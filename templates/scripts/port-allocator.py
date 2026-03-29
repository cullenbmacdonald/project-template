#!/usr/bin/env python3
"""Deterministic port allocation for dev environments.

Uses a registry file (~/.dev-ports/port-registry.json) with file locking
to prevent race conditions when multiple agents call simultaneously.

Port scheme: each branch gets a block of 10 ports at a deterministic offset.
  - DB (PostgreSQL):  15432 + (offset * 10)
  - API (backend):    18080 + (offset * 10)
  - Frontend (Vite):  15173 + (offset * 10)
"""

import argparse
import fcntl
import hashlib
import json
import os
import socket
import subprocess
import sys
from pathlib import Path

REGISTRY_PATH = Path.home() / ".dev-ports" / "port-registry.json"
MAX_OFFSET = 100

BASE_PORTS = {
    "DB_PORT": 15432,
    "API_PORT": 18080,
    "FRONTEND_PORT": 15173,
}


def get_project_name() -> str:
    """Get the project name from the git repo root directory name."""
    try:
        root = subprocess.check_output(
            ["git", "rev-parse", "--show-toplevel"],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        return os.path.basename(root)
    except (subprocess.CalledProcessError, FileNotFoundError):
        return "unknown"


def sanitize_branch_name(branch: str) -> str:
    """Convert branch name to Docker-safe identifier."""
    result = []
    for ch in branch.lower():
        if ch.isalnum() or ch == "-":
            result.append(ch)
        else:
            result.append("-")
    sanitized = "".join(result).strip("-")
    while "--" in sanitized:
        sanitized = sanitized.replace("--", "-")
    return sanitized[:32]


def port_is_free(port: int) -> bool:
    """Check if a port is available."""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        return s.connect_ex(("127.0.0.1", port)) != 0


def load_registry() -> dict:
    """Load registry. Caller must hold the lock."""
    REGISTRY_PATH.parent.mkdir(parents=True, exist_ok=True)
    if REGISTRY_PATH.exists():
        return json.loads(REGISTRY_PATH.read_text())
    return {}


def save_registry(registry: dict):
    """Save registry (caller must hold lock)."""
    REGISTRY_PATH.write_text(json.dumps(registry, indent=2) + "\n")


def get_initial_offset(key: str) -> int:
    """Hash registry key to get starting offset."""
    h = hashlib.sha256(key.encode()).hexdigest()
    return int(h[:8], 16) % MAX_OFFSET


def find_free_offset(registry: dict, key: str) -> int:
    """Find a free offset, starting from the hash-based initial offset."""
    used_offsets = set(registry.values())
    initial = get_initial_offset(key)

    for i in range(MAX_OFFSET):
        candidate = (initial + i) % MAX_OFFSET
        if candidate in used_offsets:
            continue
        all_free = all(
            port_is_free(base + candidate * 10) for base in BASE_PORTS.values()
        )
        if all_free:
            return candidate

    print("ERROR: No free port offsets available (all 100 slots used)", file=sys.stderr)
    sys.exit(1)


def registry_key(project: str, branch: str) -> str:
    """Build the registry key: project/branch."""
    return f"{project}/{branch}"


def allocate(project: str, branch: str) -> dict:
    """Allocate ports for a project/branch. Returns port assignments."""
    lock_path = REGISTRY_PATH.parent / "port-registry.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.touch()

    key = registry_key(project, branch)

    with open(lock_path) as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            reg = load_registry()

            if key in reg:
                offset = reg[key]
            else:
                offset = find_free_offset(reg, key)
                reg[key] = offset
                save_registry(reg)

            return {name: base + offset * 10 for name, base in BASE_PORTS.items()}
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)


def release(project: str, branch: str):
    """Release port allocation for a project/branch."""
    lock_path = REGISTRY_PATH.parent / "port-registry.lock"
    lock_path.parent.mkdir(parents=True, exist_ok=True)
    lock_path.touch()

    key = registry_key(project, branch)

    with open(lock_path) as lock_file:
        fcntl.flock(lock_file, fcntl.LOCK_EX)
        try:
            reg = load_registry()
            if key in reg:
                del reg[key]
                save_registry(reg)
                print(f"Released ports for: {key}")
            else:
                print(f"No allocation found for: {key}")
        finally:
            fcntl.flock(lock_file, fcntl.LOCK_UN)


def main():
    parser = argparse.ArgumentParser(description="Dev environment port allocator")
    parser.add_argument("branch", help="Git branch name")
    parser.add_argument(
        "--project",
        default=None,
        help="Project name (default: git repo directory name)",
    )
    parser.add_argument(
        "--release", action="store_true", help="Release port allocation"
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output .env file path",
    )
    parser.add_argument(
        "--json", action="store_true", help="Output as JSON"
    )
    parser.add_argument(
        "--shell", action="store_true", help="Output as shell export statements"
    )

    args = parser.parse_args()
    project = args.project or get_project_name()

    if args.release:
        release(project, args.branch)
        return

    ports = allocate(project, args.branch)
    sanitized = sanitize_branch_name(args.branch)
    compose_name = f"{project}-{sanitized}" if args.branch != "main" else project

    if args.json:
        result = {"COMPOSE_PROJECT_NAME": compose_name, **ports}
        print(json.dumps(result, indent=2))
    elif args.shell:
        print(f"export COMPOSE_PROJECT_NAME={compose_name}")
        for name, port in ports.items():
            print(f"export {name}={port}")
    elif args.output:
        lines = [f"COMPOSE_PROJECT_NAME={compose_name}"]
        for name, port in ports.items():
            lines.append(f"{name}={port}")
        args.output.write_text("\n".join(lines) + "\n")
        print(f"Generated {args.output}:")
        for line in lines:
            print(f"  {line}")
    else:
        # Default: print shell exports to stdout
        print(f"export COMPOSE_PROJECT_NAME={compose_name}")
        for name, port in ports.items():
            print(f"export {name}={port}")


if __name__ == "__main__":
    main()
