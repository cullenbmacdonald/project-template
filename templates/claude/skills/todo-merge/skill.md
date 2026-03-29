---
name: todo:merge
description: Squash-merge an existing PR, mark TODO done, tear down Docker, clean up worktree
argument-hint: [todo-number]
disable-model-invocation: true
allowed-tools: Bash,Read,Glob,Grep,Edit
---

# Merge and Clean Up TODO Work

Squash-merge an existing PR, mark the TODO as done, tear down Docker, and clean up the worktree.

**Prerequisite:** A PR must already exist (created via `/todo:start` or `/todo:pr`). If no PR exists, stop and tell the user to run `/todo:pr` first.

## Input

`$ARGUMENTS` = TODO number (e.g., `16`).

If no argument provided, list active todo worktrees (`git worktree list`, filter to `todo/*` branches) and ask the user to pick one.

## Setup

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

All paths must be absolute throughout this skill.

## Precondition Checks

### 1. Locate the worktree

```bash
git worktree list
```

Find the worktree on branch `todo/{number}-*`. Determine worktree path and branch name. If no match, report error and stop.

### 2. Verify a PR exists

```bash
BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD)
gh pr view "$BRANCH" --json state,number,url,mergedAt
```

- If **no PR exists**: Stop. Tell the user: "No PR found for this branch. Run `/todo:pr $NUMBER` first."
- If **PR is already merged**: Skip the merge step, proceed to cleanup.
- If **PR is open**: Proceed with merge.

## Merge

### 3. Squash-merge the PR

```bash
gh pr merge "$BRANCH" --squash --delete-branch
```

## Post-Merge Cleanup

### 4. Mark TODO as done

In the **main worktree** (`$REPO_ROOT`), pull latest main first:

```bash
cd "$REPO_ROOT" && git pull origin main
```

Then update the individual TODO file's `**Status**` field from `TODO` to `DONE`.

Also update the status in `docs/todos/README.md` for this item from `TODO` to `DONE`.

### 5. Commit the TODO status update

```bash
cd "$REPO_ROOT"
git add docs/todos/
git commit -m "Mark TODO #$NUMBER as done"
git push origin main
```

### 6. Tear down dev stack

```bash
cd "$WORKTREE_PATH" && ./scripts/teardown.sh 2>/dev/null
# Also remove Docker volumes for a clean teardown
if [ -f "$WORKTREE_PATH/docker-compose.dev.yml" ]; then
    cd "$WORKTREE_PATH" && docker compose -f docker-compose.dev.yml down -v 2>/dev/null
fi
```

### 7. Release port allocation

```bash
python3 "$REPO_ROOT/scripts/port-allocator.py" "$BRANCH" --release
```

### 8. Clean up worktree

```bash
cd "$REPO_ROOT"
git worktree remove "$WORKTREE_PATH"
git worktree prune
```

### 9. Delete local branch (if not already deleted by PR merge)

```bash
git branch -d "$BRANCH" 2>/dev/null || true
```

### 10. Report

Display:
- What was merged (PR number, title)
- TODO marked as done (with number)
- Docker stack removed (containers, volumes)
- Ports freed
- Worktree cleaned up
