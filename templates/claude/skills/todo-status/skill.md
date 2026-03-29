---
name: todo:status
description: Show status of all active TODO worktrees — branches, Docker stacks, commits, and PRs
disable-model-invocation: true
allowed-tools: Bash,Read,Glob,Grep
---

# TODO Status Dashboard

Show a summary of all active todo worktrees and their progress.

## Setup

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

## Steps

### 1. List all worktrees

```bash
git worktree list
```

Filter to worktrees on `todo/*` branches. If none found, say "No active TODO worktrees." and show the port registry if it exists (to catch orphaned allocations).

### 2. For each todo worktree, gather:

**Branch and TODO info:**
```bash
BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD)
# Extract TODO number from branch name (e.g., todo/16-add-caching -> 16)
# Read the TODO title from docs/todos/{number}-*.md (first line, strip "# NN: ")
```

**Docker stack health:**
```bash
if [ -f "$WORKTREE_PATH/docker-compose.dev.yml" ]; then
    cd "$WORKTREE_PATH"
    docker compose -f docker-compose.dev.yml ps --format "table {{.Name}}\t{{.Status}}" 2>/dev/null || echo "Stack not running"
else
    echo "No Docker stack"
fi
```

**Recent commits (since branching from main):**
```bash
git -C "$WORKTREE_PATH" log --oneline main..HEAD 2>/dev/null || echo "No commits yet"
```

**Uncommitted changes:**
```bash
git -C "$WORKTREE_PATH" status --short
```

**PR status (if any):**
```bash
gh pr list --head "$BRANCH" --json number,title,state,url 2>/dev/null || echo "No PR / gh not configured"
```

### 3. Format output

Present as a table:

```
## Active TODO Worktrees (2)

| # | TODO | Branch | Docker | Commits | Status | PR |
|---|------|--------|--------|---------|--------|----|
| 16 | Add Caching | todo/16-add-caching | 1/1 healthy | 3 | clean | none |
| 23 | Add Tests | todo/23-add-tests | stopped | 1 | 2 dirty | #12 (open) |
```

### 4. Port registry

Show the current port registry:

```bash
cat ~/.dev-ports/port-registry.json 2>/dev/null || echo "No port allocations"
```

If there are entries in the registry that don't correspond to any active worktree, flag them as orphaned and suggest running the release command to clean them up.

### 5. Next steps

Remind the user of available commands:
- `/todo:review <number>` to review completed work
- `/todo:merge <number>` to push, merge, and clean up
- `/todo:start <number>` to start work on another TODO
