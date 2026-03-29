---
name: todo:pr
description: Push new commits to an existing TODO PR (e.g. after addressing review comments)
argument-hint: [todo-number]
disable-model-invocation: true
allowed-tools: Bash,Read,Glob,Grep
---

# Update TODO Pull Request

Push new commits to an existing TODO PR. Use this after making additional changes (e.g. addressing review comments).

The initial PR is created automatically by the background agent when `/todo:start` finishes. This command is for pushing follow-up changes.

## Input

`$ARGUMENTS` = TODO number (e.g., `16`).

If no argument provided, list active todo worktrees (`git worktree list`, filter to `todo/*` branches) and ask the user to pick one.

## Setup

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

All paths must be absolute throughout this skill.

## Steps

### 1. Locate the worktree

```bash
git worktree list
```

Find the worktree on branch `todo/{number}-*`. Determine worktree path and branch name. If no match, report error and stop.

### 2. Check for uncommitted changes

```bash
DIRTY=$(git -C "$WORKTREE_PATH" status --porcelain)
if [ -n "$DIRTY" ]; then
    echo "WARNING: Worktree has uncommitted changes:"
    echo "$DIRTY"
    echo "ABORTING: Commit or stash changes before pushing."
fi
```

**Do NOT proceed if the worktree is dirty.** Stop and tell the user.

### 3. Push the branch

```bash
BRANCH=$(git -C "$WORKTREE_PATH" rev-parse --abbrev-ref HEAD)
git -C "$WORKTREE_PATH" push origin "$BRANCH"
```

### 4. Verify PR exists

```bash
gh pr view "$BRANCH" --json state,number,url 2>/dev/null
```

- If **no PR exists**: Create one (fallback in case the agent didn't):
  ```bash
  gh pr create --head "$BRANCH" --title "TODO #XX: <title>" --body "<summary>"
  ```
- If **PR already exists**: Push already updated it. Report the PR URL.

### 5. Report

Display:
- Branch pushed
- PR URL
- Remind user: "Run `/todo:merge $NUMBER` to squash-merge and clean up."
