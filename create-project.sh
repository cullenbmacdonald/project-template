#!/bin/bash
# Create a new project from this template
#
# Usage:
#   ./create-project.sh [project-name]
#   ./create-project.sh  # Interactive mode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}warning:${NC} $1"; }
error() { echo -e "${RED}error:${NC} $1" >&2; exit 1; }
prompt() { echo -en "${BLUE}?${NC} $1"; }

# =============================================================================
# Collect Variables
# =============================================================================

echo -e "${BOLD}Project Template Setup${NC}"
echo ""

# Project name
if [[ $# -ge 1 ]]; then
    PROJECT_NAME="$1"
else
    prompt "Project name: "
    read -r PROJECT_NAME
fi

if [[ -z "$PROJECT_NAME" ]]; then
    error "Project name is required"
fi

# Validate project name (lowercase, hyphens, no spaces)
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    error "Project name must be lowercase, start with a letter, and contain only letters, numbers, and hyphens"
fi

# Check if directory exists
if [[ -d "$PROJECT_NAME" ]]; then
    error "Directory '$PROJECT_NAME' already exists"
fi

# Backend language
echo ""
echo "Backend language:"
echo "  1) Go"
echo "  2) Python"
echo "  3) Node.js"
echo "  4) None (frontend only)"
prompt "Choose [1-4]: "
read -r BACKEND_CHOICE

case $BACKEND_CHOICE in
    1) BACKEND_LANG="go" ;;
    2) BACKEND_LANG="python" ;;
    3) BACKEND_LANG="node" ;;
    4) BACKEND_LANG="none" ;;
    *) error "Invalid choice" ;;
esac

# Frontend
echo ""
prompt "Include frontend? [Y/n]: "
read -r FRONTEND_CHOICE
FRONTEND_CHOICE="${FRONTEND_CHOICE:-y}"
if [[ "$FRONTEND_CHOICE" =~ ^[Yy] ]]; then
    HAS_FRONTEND="yes"
else
    HAS_FRONTEND="no"
fi

# Validate we have at least one component
if [[ "$BACKEND_LANG" == "none" && "$HAS_FRONTEND" == "no" ]]; then
    error "Must have at least a backend or frontend"
fi

# GitHub org (optional)
echo ""
prompt "GitHub org/username (optional, press Enter to skip): "
read -r GITHUB_ORG
GITHUB_ORG="${GITHUB_ORG:-}"

# Domain (optional)
echo ""
prompt "Production domain (optional, press Enter to skip): "
read -r DOMAIN
DOMAIN="${DOMAIN:-example.com}"

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${BOLD}Configuration:${NC}"
echo "  Project name:  $PROJECT_NAME"
echo "  Backend:       $BACKEND_LANG"
echo "  Frontend:      $HAS_FRONTEND"
if [[ -n "$GITHUB_ORG" ]]; then
    echo "  GitHub org:    $GITHUB_ORG"
fi
echo "  Domain:        $DOMAIN"
echo ""

prompt "Create project? [Y/n]: "
read -r CONFIRM
CONFIRM="${CONFIRM:-y}"
if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
    echo "Aborted."
    exit 0
fi

# =============================================================================
# Create Project
# =============================================================================

log "Creating project directory..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Helper to substitute variables in a file
substitute() {
    local file="$1"
    sed -i.bak \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{GITHUB_ORG}}|$GITHUB_ORG|g" \
        -e "s|{{DOMAIN}}|$DOMAIN|g" \
        -e "s|{{BACKEND_LANG}}|$BACKEND_LANG|g" \
        "$file"
    rm -f "$file.bak"
}

# Copy core files
log "Copying core files..."
cp -r "$TEMPLATES_DIR/core/.githooks" .
cp "$TEMPLATES_DIR/core/.gitignore" .
cp "$TEMPLATES_DIR/core/.editorconfig" .

# Generate CLAUDE.md based on selected components
generate_claude_md() {
    cat > CLAUDE.md << CLAUDE_HEADER
# CLAUDE.md

This file provides guidance to Claude Code when working with this codebase.

## Project: $PROJECT_NAME

## Project Structure

\`\`\`
$PROJECT_NAME/
├── Makefile               # Root coordinator
├── .githooks/             # Git hooks (auto-configured)
CLAUDE_HEADER

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> CLAUDE.md << CLAUDE_BACKEND
├── backend/               # Backend ($BACKEND_LANG)
│   └── Makefile
CLAUDE_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> CLAUDE.md << CLAUDE_FRONTEND
├── frontend/              # Frontend (npm)
│   └── Makefile
CLAUDE_FRONTEND
    fi

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> CLAUDE.md << CLAUDE_INFRA
├── infra/                 # Deployment infrastructure
│   ├── docker-compose.yml
│   ├── Caddyfile
│   └── deploy.sh
CLAUDE_INFRA
    fi

    cat >> CLAUDE.md << 'CLAUDE_SCRIPTS'
├── scripts/               # Dev environment scripts
│   ├── port-allocator.py  # Deterministic port allocation
│   ├── env.sh             # Environment variable setup
│   ├── dev.sh             # Start dev stack
│   └── teardown.sh        # Stop dev stack
├── docs/todos/            # TODO tracking
│   ├── README.md          # TODO index
│   └── TEMPLATE.md        # Template for new TODOs
└── .claude/skills/        # Claude TODO management skills
CLAUDE_SCRIPTS

    cat >> CLAUDE.md << 'CLAUDE_COMMANDS'
```

## Common Commands

```bash
make lint      # Lint all components
make test      # Test all components
make build     # Build all components
make clean     # Clean all artifacts
make dev       # Start full dev stack
make teardown  # Stop all dev services
make help      # Show all targets
```

## Development

```bash
make dev        # Start full dev stack (Docker + backend + frontend)
make teardown   # Stop all dev services and Docker containers
```

The dev stack uses deterministic port allocation per git branch, so multiple
branches can run simultaneously without port conflicts. Ports are stored in
`~/.dev-ports/port-registry.json`.

Run `make dev` to see the actual ports for your branch.

### Dev Scripts

- `scripts/env.sh` - Sources port allocator, exports environment variables
- `scripts/dev.sh` - Multi-phase startup (Docker, DB, backend, frontend)
- `scripts/teardown.sh` - Stops all processes and Docker containers
- `scripts/port-allocator.py` - Allocates unique port blocks per branch

## TODO Management

TODOs are tracked in `docs/todos/`. Each TODO is a markdown file with structured
fields (Tier, Severity, Effort, Status, Action Items, Relevant Files).

### Claude Skills

| Command | Description |
|---------|-------------|
| `/todo:list` | Show all open TODOs grouped by tier |
| `/todo:start N` | Create worktree, allocate ports, spawn background agent |
| `/todo:status` | Dashboard of active worktrees and Docker stacks |
| `/todo:review N` | Run tests/lint, code review against action items |
| `/todo:pr N` | Push follow-up changes to existing PR |
| `/todo:merge N` | Squash-merge PR, mark done, tear down, clean up |

### Creating a TODO

Copy `docs/todos/TEMPLATE.md` to `docs/todos/NN-short-name.md` and fill in
the fields. Add a row to `docs/todos/README.md`.

CLAUDE_COMMANDS

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> CLAUDE.md << 'CLAUDE_DEPLOY'
## Deployment

```bash
make deploy DEPLOY_HOST=user@host    # Deploy to server
./infra/deploy.sh user@host --init   # First-time setup
```

CLAUDE_DEPLOY
    fi

    cat >> CLAUDE.md << 'CLAUDE_HOOKS'
## Git Hooks

Hooks run automatically:
- **Pre-commit**: Formats code and runs linters on staged files
- **Pre-push**: Runs tests and builds on changed directories

## Code Style

- Code must pass `make lint` before committing
- Tests must pass before pushing
- Hooks enforce this automatically
CLAUDE_HOOKS
}

generate_claude_md

# Generate .githooks based on components
log "Configuring git hooks..."
generate_pre_commit() {
    cat > .githooks/pre-commit << 'HOOK_START'
#!/bin/sh
# Pre-commit hook: runs checks for changed directories

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
STAGED_FILES=$(git diff --cached --name-only)

HOOK_START

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_BACKEND'
BACKEND_CHANGED=$(echo "$STAGED_FILES" | grep -E '^backend/' || true)
HOOK_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_FRONTEND'
FRONTEND_CHANGED=$(echo "$STAGED_FILES" | grep -E '^frontend/' || true)
HOOK_FRONTEND
    fi

    # Build the check condition
    local check_cond=""
    if [[ "$BACKEND_LANG" != "none" ]]; then
        check_cond='[ -z "$BACKEND_CHANGED" ]'
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        if [[ -n "$check_cond" ]]; then
            check_cond="$check_cond && "'[ -z "$FRONTEND_CHANGED" ]'
        else
            check_cond='[ -z "$FRONTEND_CHANGED" ]'
        fi
    fi

    cat >> .githooks/pre-commit << HOOK_CHECK
if $check_cond; then
    echo "No relevant files staged. Skipping checks."
    exit 0
fi

echo "Running pre-commit checks..."
HOOK_CHECK

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_BACKEND_CHECK'

if [ -n "$BACKEND_CHANGED" ]; then
    echo ""
    echo "=== Backend ==="
    cd "$REPO_ROOT/backend"

    echo "Running format..."
    make fmt 2>/dev/null || true

    if ! git diff --quiet; then
        echo "Formatting changes detected, adding to commit..."
        git add -u
    fi

    echo "Running lint..."
    make lint
    if [ $? -ne 0 ]; then
        echo "Backend lint failed. Please fix the issues before committing."
        exit 1
    fi
fi
HOOK_BACKEND_CHECK
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_FRONTEND_CHECK'

if [ -n "$FRONTEND_CHANGED" ]; then
    echo ""
    echo "=== Frontend ==="
    cd "$REPO_ROOT/frontend"

    if [ -f "tsconfig.json" ]; then
        echo "Running TypeScript check..."
        npx tsc -b
        if [ $? -ne 0 ]; then
            echo "TypeScript check failed. Please fix the issues before committing."
            exit 1
        fi
    fi

    echo "Running lint..."
    make lint
    if [ $? -ne 0 ]; then
        echo "Frontend lint failed. Please fix the issues before committing."
        exit 1
    fi
fi
HOOK_FRONTEND_CHECK
    fi

    cat >> .githooks/pre-commit << 'HOOK_END'

echo ""
echo "Pre-commit checks passed."
HOOK_END

    chmod +x .githooks/pre-commit
}

generate_pre_push() {
    cat > .githooks/pre-push << 'HOOK_START'
#!/bin/sh
# Pre-push hook: runs tests and build for changed directories

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"

read local_ref local_sha remote_ref remote_sha

if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH"..."$local_sha" 2>/dev/null || git diff --name-only "$local_sha")
else
    CHANGED_FILES=$(git diff --name-only "$remote_sha"..."$local_sha")
fi

HOOK_START

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-push << 'HOOK_BACKEND'
BACKEND_CHANGED=$(echo "$CHANGED_FILES" | grep -E '^backend/' || true)
HOOK_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-push << 'HOOK_FRONTEND'
FRONTEND_CHANGED=$(echo "$CHANGED_FILES" | grep -E '^frontend/' || true)
HOOK_FRONTEND
    fi

    # Build the check condition
    local check_cond=""
    if [[ "$BACKEND_LANG" != "none" ]]; then
        check_cond='[ -z "$BACKEND_CHANGED" ]'
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        if [[ -n "$check_cond" ]]; then
            check_cond="$check_cond && "'[ -z "$FRONTEND_CHANGED" ]'
        else
            check_cond='[ -z "$FRONTEND_CHANGED" ]'
        fi
    fi

    cat >> .githooks/pre-push << HOOK_CHECK
if $check_cond; then
    echo "No relevant files in push. Skipping checks."
    exit 0
fi

echo "Running pre-push checks..."
HOOK_CHECK

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-push << 'HOOK_BACKEND_CHECK'

if [ -n "$BACKEND_CHANGED" ]; then
    echo ""
    echo "=== Backend Tests ==="
    cd "$REPO_ROOT/backend"

    echo "Running tests..."
    make test
    if [ $? -ne 0 ]; then
        echo "Tests failed. Please fix the issues before pushing."
        exit 1
    fi

    echo ""
    echo "=== Backend Build ==="
    make build
    if [ $? -ne 0 ]; then
        echo "Backend build failed. Please fix the issues before pushing."
        exit 1
    fi
fi
HOOK_BACKEND_CHECK
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-push << 'HOOK_FRONTEND_CHECK'

if [ -n "$FRONTEND_CHANGED" ]; then
    echo ""
    echo "=== Frontend Build ==="
    cd "$REPO_ROOT/frontend"

    make build
    if [ $? -ne 0 ]; then
        echo "Frontend build failed. Please fix the issues before pushing."
        exit 1
    fi
fi
HOOK_FRONTEND_CHECK
    fi

    cat >> .githooks/pre-push << 'HOOK_END'

echo ""
echo "Pre-push checks passed."
HOOK_END

    chmod +x .githooks/pre-push
}

generate_pre_commit
generate_pre_push

# Generate dev environment scripts
log "Setting up dev scripts..."
mkdir -p scripts

# Copy port allocator (always needed for dev scripts)
cp "$TEMPLATES_DIR/scripts/port-allocator.py" scripts/
chmod +x scripts/port-allocator.py

# Generate env.sh
generate_env_sh() {
    cat > scripts/env.sh << 'ENV_HEADER'
#!/bin/bash
# Detect branch and export all port/URL vars.
# Source this file: source scripts/env.sh

# Resolve script location robustly
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "$0" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
fi
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Get current branch name
BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

# Use port-allocator to get deterministic ports for this branch
eval "$(python3 "$SCRIPT_DIR/port-allocator.py" "$BRANCH" --shell)"

ENV_HEADER

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/env.sh << 'ENV_BACKEND'
# Backend env vars
export PORT="$API_PORT"
export SERVER_PORT="$API_PORT"
export DATABASE_HOST="localhost"
export DATABASE_PORT="$DB_PORT"
export DATABASE_URL="postgres://${DB_USER:-app}:${DB_PASSWORD:-devpassword}@localhost:${DB_PORT}/${DB_NAME:-app}?sslmode=disable"
ENV_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" && "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/env.sh << 'ENV_CORS'
export CORS_ALLOWED_ORIGINS="http://localhost:${FRONTEND_PORT}"
ENV_CORS
    fi

    chmod +x scripts/env.sh
}

generate_env_sh

# Generate dev.sh
generate_dev_sh() {
    cat > scripts/dev.sh << 'DEV_HEADER'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Check for python3
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 is required for port allocation"; exit 1; }

source "$SCRIPT_DIR/env.sh"

BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
PID_DIR="/tmp/${COMPOSE_PROJECT_NAME}-dev"
mkdir -p "$PID_DIR"

DEV_HEADER

    # Print URLs based on components
    cat >> scripts/dev.sh << 'DEV_BANNER'
echo "=== Dev Stack (${BRANCH}) ==="
DEV_BANNER

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/dev.sh << 'DEV_BANNER_BACKEND'
echo "  API:      http://localhost:${API_PORT}"
echo "  DB:       localhost:${DB_PORT}"
DEV_BANNER_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> scripts/dev.sh << 'DEV_BANNER_FRONTEND'
echo "  Frontend: http://localhost:${FRONTEND_PORT}"
DEV_BANNER_FRONTEND
    fi

    echo 'echo ""' >> scripts/dev.sh

    # Phase 1: Docker (if backend)
    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/dev.sh << 'DEV_DOCKER'

# --- Phase 1: Docker infrastructure ---
echo "Starting Docker services..."
docker compose -f "$PROJECT_ROOT/docker-compose.dev.yml" up -d

echo "Waiting for database..."
DB_CONTAINER=$(docker compose -f "$PROJECT_ROOT/docker-compose.dev.yml" ps -q db)
for i in $(seq 1 30); do
  if docker exec "$DB_CONTAINER" pg_isready -U "${DB_USER:-app}" > /dev/null 2>&1; then
    echo "Database is ready."
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "ERROR: Database did not become ready in 30s"
    exit 1
  fi
  sleep 1
done

DEV_DOCKER

        # Phase 2: Backend
        cat >> scripts/dev.sh << 'DEV_BACKEND'
# --- Phase 2: Backend ---
if lsof -i ":${API_PORT}" > /dev/null 2>&1; then
  echo "API already running on port ${API_PORT}."
else
  echo "Starting backend on port ${API_PORT}..."
  cd "$PROJECT_ROOT/backend"
  PORT="$API_PORT" make run > "$PID_DIR/api.log" 2>&1 &
  API_PID=$!
  echo "$API_PID" > "$PID_DIR/api.pid"
  cd "$PROJECT_ROOT"

  for i in $(seq 1 30); do
    if curl -sf "http://localhost:${API_PORT}/health" > /dev/null 2>&1; then
      echo "API is healthy."
      break
    fi
    if [ "$i" -eq 30 ]; then
      echo "WARNING: API may still be starting (check $PID_DIR/api.log)"
    fi
    sleep 1
  done
fi

DEV_BACKEND
    fi

    # Phase 3: Frontend (if selected)
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> scripts/dev.sh << 'DEV_FRONTEND'
# --- Frontend ---
if lsof -i ":${FRONTEND_PORT}" > /dev/null 2>&1; then
  echo "Frontend already running on port ${FRONTEND_PORT}."
else
  echo "Starting frontend on port ${FRONTEND_PORT}..."
  cd "$PROJECT_ROOT/frontend"
  npx vite --port "${FRONTEND_PORT}" > "$PID_DIR/frontend.log" 2>&1 &
  FRONTEND_PID=$!
  echo "$FRONTEND_PID" > "$PID_DIR/frontend.pid"
  cd "$PROJECT_ROOT"

  for i in $(seq 1 15); do
    if curl -sf "http://localhost:${FRONTEND_PORT}" > /dev/null 2>&1; then
      echo "Frontend is ready."
      break
    fi
    if [ "$i" -eq 15 ]; then
      echo "WARNING: Frontend may still be starting (check $PID_DIR/frontend.log)"
    fi
    sleep 1
  done
fi

DEV_FRONTEND
    fi

    # Ready banner
    cat >> scripts/dev.sh << 'DEV_READY'
echo ""
echo "=== Ready ==="
DEV_READY

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/dev.sh << 'DEV_READY_BACKEND'
echo "  API:      http://localhost:${API_PORT}"
echo "  DB:       localhost:${DB_PORT}"
DEV_READY_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> scripts/dev.sh << 'DEV_READY_FRONTEND'
echo "  Frontend: http://localhost:${FRONTEND_PORT}"
DEV_READY_FRONTEND
    fi

    echo 'echo "  Logs:     $PID_DIR/*.log"' >> scripts/dev.sh

    chmod +x scripts/dev.sh
}

generate_dev_sh

# Generate teardown.sh
generate_teardown_sh() {
    cat > scripts/teardown.sh << 'TEARDOWN_HEADER'
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/env.sh"

BRANCH=$(git -C "$PROJECT_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
PID_DIR="/tmp/${COMPOSE_PROJECT_NAME}-dev"

echo "=== Tearing down dev stack (${BRANCH}) ==="

# Stop native processes
TEARDOWN_HEADER

    # Kill processes based on components
    local services=""
    [[ "$BACKEND_LANG" != "none" ]] && services="$services api"
    [[ "$HAS_FRONTEND" == "yes" ]] && services="$services frontend"

    cat >> scripts/teardown.sh << TEARDOWN_KILL
for service in$services; do
TEARDOWN_KILL

    cat >> scripts/teardown.sh << 'TEARDOWN_KILL_BODY'
  PID_FILE="$PID_DIR/${service}.pid"
  if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if kill -0 "$PID" 2>/dev/null; then
      echo "Stopping ${service} (PID $PID)..."
      kill "$PID" 2>/dev/null || true
    fi
    rm -f "$PID_FILE"
  fi
done

TEARDOWN_KILL_BODY

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/teardown.sh << 'TEARDOWN_DOCKER'
# Stop Docker services
docker compose -f "$PROJECT_ROOT/docker-compose.dev.yml" down

TEARDOWN_DOCKER
    fi

    cat >> scripts/teardown.sh << 'TEARDOWN_CLEANUP'
rm -rf "$PID_DIR"

echo "Stack stopped."
TEARDOWN_CLEANUP

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> scripts/teardown.sh << 'TEARDOWN_HINT'
echo "To also remove data: docker compose -f docker-compose.dev.yml down -v"
TEARDOWN_HINT
    fi

    chmod +x scripts/teardown.sh
}

generate_teardown_sh

# Copy ensure-hooks.sh
cp "$TEMPLATES_DIR/core/.githooks/ensure-hooks.sh" .githooks/
chmod +x .githooks/ensure-hooks.sh

# Create .github/workflows directory
mkdir -p .github/workflows

# Copy backend files
if [[ "$BACKEND_LANG" != "none" ]]; then
    log "Setting up $BACKEND_LANG backend..."
    cp -r "$TEMPLATES_DIR/backend-$BACKEND_LANG" backend

    # Substitute variables in backend files
    find backend -name "*.tmpl" | while read -r tmpl; do
        mv "$tmpl" "${tmpl%.tmpl}"
        substitute "${tmpl%.tmpl}"
    done

    # Copy workflow
    cp "$TEMPLATES_DIR/backend-$BACKEND_LANG/.github/workflows/backend.yml" .github/workflows/
fi

# Copy frontend files
if [[ "$HAS_FRONTEND" == "yes" ]]; then
    log "Setting up frontend..."
    cp -r "$TEMPLATES_DIR/frontend" frontend

    # Substitute variables
    find frontend -name "*.tmpl" | while read -r tmpl; do
        mv "$tmpl" "${tmpl%.tmpl}"
        substitute "${tmpl%.tmpl}"
    done

    # Copy workflow
    cp "$TEMPLATES_DIR/frontend/.github/workflows/frontend.yml" .github/workflows/
fi

# Copy and configure infra (if we have a backend)
if [[ "$BACKEND_LANG" != "none" ]]; then
    log "Setting up infrastructure..."
    mkdir -p infra

    cp "$TEMPLATES_DIR/infra/Makefile" infra/
    cp "$TEMPLATES_DIR/infra/cloud-init.yaml" infra/
    cp "$TEMPLATES_DIR/infra/deploy.sh" infra/
    chmod +x infra/deploy.sh

    # Copy appropriate Dockerfile
    cp "$TEMPLATES_DIR/infra/Dockerfile-$BACKEND_LANG" infra/Dockerfile

    # Copy and substitute templates
    cp "$TEMPLATES_DIR/infra/docker-compose.yml.tmpl" infra/docker-compose.yml
    cp "$TEMPLATES_DIR/infra/Caddyfile.tmpl" infra/Caddyfile
    cp "$TEMPLATES_DIR/infra/.env.example.tmpl" infra/.env.example

    substitute infra/docker-compose.yml
    substitute infra/Caddyfile
    substitute infra/.env.example

    # Adjust Caddyfile if no frontend
    if [[ "$HAS_FRONTEND" == "no" ]]; then
        # Remove frontend-specific sections from Caddyfile
        sed -i.bak '/# Frontend SPA/,/file_server/d' infra/Caddyfile
        rm -f infra/Caddyfile.bak
    fi
fi

# Copy dev docker-compose (if backend — it runs the database)
if [[ "$BACKEND_LANG" != "none" ]]; then
    log "Setting up dev docker-compose..."
    cp "$TEMPLATES_DIR/docker-compose.dev.yml.tmpl" docker-compose.dev.yml
    substitute docker-compose.dev.yml
fi

# Copy Claude skills (TODO management)
log "Setting up Claude TODO skills..."
mkdir -p .claude/skills
cp -r "$TEMPLATES_DIR/claude/skills/"* .claude/skills/

# Copy TODO docs structure
log "Setting up TODO tracking..."
mkdir -p docs/todos
cp "$TEMPLATES_DIR/docs/todos/README.md" docs/todos/
cp "$TEMPLATES_DIR/docs/todos/TEMPLATE.md" docs/todos/

# Generate root Makefile
log "Generating root Makefile..."
generate_makefile() {
    cat > Makefile << 'MAKEFILE_HEADER'
# Root Makefile - Coordinates all subdirectory builds

.PHONY: lint test build clean help install deploy dev teardown

.DEFAULT_GOAL := help

# Configuration
VERSION ?= dev
DEPLOY_HOST ?=

MAKEFILE_HEADER

    # Add phony declarations based on components
    if [[ "$BACKEND_LANG" != "none" ]]; then
        echo ".PHONY: lint-backend test-backend build-backend clean-backend" >> Makefile
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        echo ".PHONY: lint-frontend test-frontend build-frontend clean-frontend install-frontend" >> Makefile
    fi

    echo "" >> Makefile
    echo "# ==============================================================================" >> Makefile
    echo "# Aggregate Targets" >> Makefile
    echo "# ==============================================================================" >> Makefile
    echo "" >> Makefile

    # Lint target
    local lint_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && lint_deps="lint-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && lint_deps="$lint_deps lint-frontend"
    echo "lint: $lint_deps" >> Makefile
    echo '	@echo "All linting complete"' >> Makefile
    echo "" >> Makefile

    # Test target
    local test_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && test_deps="test-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && test_deps="$test_deps test-frontend"
    echo "test: $test_deps" >> Makefile
    echo '	@echo "All tests complete"' >> Makefile
    echo "" >> Makefile

    # Build target
    local build_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && build_deps="build-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && build_deps="$build_deps build-frontend"
    echo "build: $build_deps" >> Makefile
    echo '	@echo "All builds complete"' >> Makefile
    echo "" >> Makefile

    # Clean target
    local clean_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && clean_deps="clean-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && clean_deps="$clean_deps clean-frontend"
    echo "clean: $clean_deps" >> Makefile
    echo '	@echo "All clean complete"' >> Makefile
    echo "" >> Makefile

    # Install target
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        echo "install: install-frontend" >> Makefile
        echo '	@echo "All dependencies installed"' >> Makefile
    else
        echo "install:" >> Makefile
        echo '	@echo "No dependencies to install"' >> Makefile
    fi
    echo "" >> Makefile

    # Backend targets
    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> Makefile << 'BACKEND_TARGETS'
# ==============================================================================
# Backend Targets
# ==============================================================================

lint-backend:
	$(MAKE) -C backend lint

test-backend:
	$(MAKE) -C backend test

build-backend:
	$(MAKE) -C backend build

clean-backend:
	$(MAKE) -C backend clean

BACKEND_TARGETS
    fi

    # Frontend targets
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> Makefile << 'FRONTEND_TARGETS'
# ==============================================================================
# Frontend Targets
# ==============================================================================

lint-frontend:
	$(MAKE) -C frontend lint

test-frontend:
	$(MAKE) -C frontend test

build-frontend:
	$(MAKE) -C frontend build

clean-frontend:
	$(MAKE) -C frontend clean

install-frontend:
	$(MAKE) -C frontend install

FRONTEND_TARGETS
    fi

    # Deploy target (only if we have infra)
    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> Makefile << 'DEPLOY_TARGET'
# ==============================================================================
# Deploy Targets
# ==============================================================================

deploy:
ifeq ($(DEPLOY_HOST),)
	$(error DEPLOY_HOST is required. Usage: make deploy DEPLOY_HOST=user@host)
endif
	./infra/deploy.sh $(DEPLOY_HOST)

DEPLOY_TARGET
    fi

    # Dev targets
    echo "# ==============================================================================" >> Makefile
    echo "# Development" >> Makefile
    echo "# ==============================================================================" >> Makefile
    echo "" >> Makefile
    echo "dev: ## Start full dev stack" >> Makefile
    echo '	@./scripts/dev.sh' >> Makefile
    echo "" >> Makefile
    echo "teardown: ## Stop all dev services" >> Makefile
    echo '	@./scripts/teardown.sh' >> Makefile
    echo "" >> Makefile

    # Help target
    cat >> Makefile << 'HELP_TARGET'
# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "Project - Unified Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Aggregate Targets:"
	@echo "  lint      - Lint all components"
	@echo "  test      - Test all components"
	@echo "  build     - Build all components"
	@echo "  clean     - Clean all build artifacts"
	@echo "  install   - Install all dependencies"
	@echo ""
	@echo "Development:"
	@echo "  dev       - Start full dev stack (Docker + backend + frontend)"
	@echo "  teardown  - Stop all dev services"
HELP_TARGET

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> Makefile << 'HELP_DEPLOY'
	@echo ""
	@echo "Deploy:"
	@echo "  deploy DEPLOY_HOST=user@host    - Deploy to server"
HELP_DEPLOY
    fi
}

generate_makefile

# Initialize git repo
log "Initializing git repository..."
git init -q
git config core.hooksPath .githooks

# Create initial commit
git add -A
git commit -q -m "Initial project from template"

# =============================================================================
# Done
# =============================================================================

echo ""
echo -e "${GREEN}Project created successfully!${NC}"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_NAME"
if [[ "$HAS_FRONTEND" == "yes" ]]; then
    echo "  # Set up your frontend framework:"
    echo "  cd frontend && npm create vite@latest . -- --template react-ts"
fi
echo "  make build    # Verify everything works"
echo "  make dev      # Start dev environment"
echo ""
echo "TODO management:"
echo "  /todo:list    # Show open TODOs"
echo "  /todo:start N # Start work on a TODO"
echo ""
if [[ -n "$GITHUB_ORG" ]]; then
    echo "To create a GitHub repo:"
    echo "  gh repo create $GITHUB_ORG/$PROJECT_NAME --source=. --push"
fi
