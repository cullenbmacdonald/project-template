---
name: todo:list
description: List all open TODO items from docs/todos/README.md
disable-model-invocation: true
allowed-tools: Read,Glob
---

# List Open TODOs

Read `docs/todos/README.md` and display all items with status `TODO` in a concise table.

## Steps

### 1. Read the README

Read `docs/todos/README.md` from the repository root.

### 2. Read each open TODO file

For each row where Status = `TODO`, read the individual file to get the **Effort** and **Severity** fields.

### 3. Display open items

Show them grouped by tier/section:

```
## Tier 1: Reliability

| # | Title | Severity | Effort |
|---|-------|----------|--------|
| 3 | Fix race condition in worker | HIGH | M (4-16 hours) |

## Tier 3: Scalability

| # | Title | Severity | Effort |
|---|-------|----------|--------|
| 7 | Add caching layer | MEDIUM | L (16+ hours) |
```

### 4. Summary and next steps

Show the total count of open vs done items.

Then: "Run `/todo:start <number>` to start work on a TODO, or `/todo:status` to check active worktrees."
