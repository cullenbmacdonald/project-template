---
name: todo:review
description: Review work in a TODO worktree — runs tests, lint, and code review
argument-hint: [todo-number]
disable-model-invocation: true
allowed-tools: Bash,Read,Glob,Grep,Agent
---

# Review TODO Work

Review the code changes in a todo worktree by running tests, linting, and performing a code review.

## Input

`$ARGUMENTS` = TODO number (e.g., `16`).

If no argument provided, list active todo worktrees (`git worktree list`, filter to `todo/*` branches) and ask the user to pick one.

## Setup

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
```

## Steps

### 1. Locate the worktree

```bash
git worktree list
```

Find the worktree on branch `todo/{number}-*`. Determine the absolute worktree path. If no match, report error and stop.

### 2. Read the original TODO

Read the TODO file (`$REPO_ROOT/docs/todos/{number}-*.md`) to understand what was supposed to be implemented. Note the action items checklist.

### 3. Check dev stack

```bash
if [ -f "$WORKTREE_PATH/docker-compose.dev.yml" ]; then
    cd "$WORKTREE_PATH" && docker compose -f docker-compose.dev.yml ps 2>/dev/null
fi
```

If the stack is stopped but tests need it, ask the user if they want to start it with `cd "$WORKTREE_PATH" && ./scripts/dev.sh`.

### 4. Run tests and lint

Run the appropriate suite based on what files changed:

```bash
cd "$WORKTREE_PATH"
CHANGED=$(git diff main...HEAD --name-only)

# Run backend tests if backend files changed
if echo "$CHANGED" | grep -q "^backend/"; then
    echo "Running backend tests and lint..."
    cd "$WORKTREE_PATH" && make test-backend && make lint-backend
fi

# Run frontend lint if frontend files changed
if echo "$CHANGED" | grep -q "^frontend/"; then
    echo "Running frontend lint..."
    cd "$WORKTREE_PATH" && make lint-frontend
fi
```

Report results clearly: pass/fail for each.

### 5. Show diff summary

```bash
cd "$WORKTREE_PATH"
git diff main...HEAD --stat
```

Then read the full diff. For large diffs (>500 lines), use an Explore agent to assist with the review.

### 6. Code review

Review the diff against:
- **Completeness**: Are ALL action items from the TODO addressed? List each one with a checkmark or X.
- **CLAUDE.md conventions**: Follow project code style conventions.
- **Security**: No vulnerabilities introduced (OWASP top 10)
- **Tests**: New code has tests where appropriate
- **Scope**: No unnecessary changes beyond what the TODO requires
- **Correctness**: Logic bugs, edge cases, error handling

### 7. Report

Provide a structured summary:

```
## Review: TODO #XX - <title>

### Action Items
- [x] Item 1 (implemented in file.go:42)
- [ ] Item 2 (NOT addressed)

### Tests
Backend: 42 passed, 0 failed
Frontend: lint clean

### Code Review
- <observations>
- <concerns>
- <suggestions>

### Recommendation
Approve / Needs Changes
<specific items to fix if Needs Changes>
```

If approved, tell the user: "Ready to merge. Run `/todo:merge $NUMBER` to push, create PR, and clean up."
