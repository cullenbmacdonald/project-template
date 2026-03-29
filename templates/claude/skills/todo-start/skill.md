---
name: todo:start
description: Start work on a TODO item — creates a git worktree, allocates ports, starts Docker, and spawns a background agent
argument-hint: [todo-number]
disable-model-invocation: true
allowed-tools: Bash,Read,Glob,Grep,Write,Edit,Agent
---

# Start Work on a TODO

Create an isolated git worktree with its own Docker stack, then spawn a background agent to implement the TODO. The main session stays free for status checks and kicking off more work.

## Input

`$ARGUMENTS` contains a TODO number (e.g., `16` or `todo-16`). If empty or ambiguous, run `/todo:list` logic (read `docs/todos/README.md`, show open items) and ask the user to pick one.

## Phase 1: Setup (main session)

### 1. Read the TODO file

Parse the number from `$ARGUMENTS` and read `docs/todos/{number}-*.md` (glob for the file). Extract:
- Title
- Severity / Effort
- Action items
- Relevant files

Save the full TODO contents to include in the agent prompt later.

### 2. Generate branch name

Create a branch name from the TODO file name:
- `docs/todos/16-add-caching.md` -> `todo/16-add-caching`

### 3. Preflight checks

```bash
# Verify Docker is running (skip if no docker-compose.dev.yml)
if [ -f "docker-compose.dev.yml" ]; then
    docker info > /dev/null 2>&1 || { echo "ERROR: Docker is not running"; exit 1; }
fi

# Verify branch doesn't already exist
git rev-parse --verify "$BRANCH" 2>/dev/null && { echo "ERROR: Branch $BRANCH already exists. Use /todo:status to check on it."; exit 1; }
```

### 4. Determine repo root and worktree path

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
PROJECT_NAME=$(basename "$REPO_ROOT")
WORKTREE_PATH="$REPO_ROOT/../${PROJECT_NAME}-todo-$NUMBER"
```

All subsequent paths must be absolute to avoid CWD confusion.

### 5. Fetch latest main and create worktree

```bash
git fetch origin main 2>/dev/null || echo "No remote, using local main"
git worktree add "$WORKTREE_PATH" -b "$BRANCH" origin/main
```

### 6. Allocate ports and generate .env

```bash
python3 "$REPO_ROOT/scripts/port-allocator.py" "$BRANCH" --output "$WORKTREE_PATH/.env"
```

This creates a `.env` file with unique `COMPOSE_PROJECT_NAME`, `DB_PORT`, `API_PORT`, and `FRONTEND_PORT` so multiple worktrees can run Docker stacks simultaneously without port or container name collisions.

## Phase 2: Spawn Background Agent

Spawn the background agent immediately after worktree creation and port allocation. Docker setup is the agent's responsibility -- this keeps the main session free.

### Agent prompt must include

1. The full contents of the TODO file (action items, relevant files, etc.)
2. The absolute worktree path -- tell the agent: "Your working directory is $WORKTREE_PATH. All file operations must use this path."
3. The branch name
4. The allocated ports from the .env file
5. Instructions to:
   - **First**, start the full dev stack:
     ```
     cd $WORKTREE_PATH && ./scripts/dev.sh
     ```
     This starts Docker infrastructure, runs DB readiness checks, and launches the backend and frontend. It reads ports from the `.env` file generated in Phase 1.
   - Read `$WORKTREE_PATH/CLAUDE.md` for project conventions
   - Implement ALL action items from the TODO
   - Run tests and lint: `cd $WORKTREE_PATH && make test && make lint`
   - Commit the work with message: `"TODO #XX: <title>"` (do NOT push)
   - Do NOT modify files outside the worktree
   - **Last step**: Push the branch and create a PR:
     ```bash
     git -C $WORKTREE_PATH push -u origin $BRANCH
     ```
     Then create the PR using `gh pr create` from within the worktree:
     ```bash
     cd $WORKTREE_PATH && gh pr create --head "$BRANCH" --title "TODO #XX: <title>" --body "<summary of changes>"
     ```
     The PR body should summarize what was implemented (bullet points) and include a test plan.

Use `Agent` with `run_in_background: true`.

### 7. Report to user

Display:
- TODO title and number
- Worktree path (absolute)
- Branch name
- Allocated ports (from .env)
- Confirmation that the background agent has been spawned

Tell the user:
- Check progress with `/todo:status`
- They will be notified when the agent finishes
- When done, use `/todo:review $NUMBER` to review the work

## Rollback on failure

If ANY step fails after worktree creation, clean up everything using absolute paths:

```bash
# Tear down dev stack (Docker + native processes)
cd "$WORKTREE_PATH" && ./scripts/teardown.sh 2>/dev/null

# Release port allocation
python3 "$REPO_ROOT/scripts/port-allocator.py" "$BRANCH" --release

# Remove worktree
git worktree remove "$WORKTREE_PATH" --force 2>/dev/null

echo "ROLLBACK: Cleaned up failed worktree $WORKTREE_PATH"
```

Report what failed and what was cleaned up.
