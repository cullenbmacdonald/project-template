# CLAUDE.md

This file provides guidance to Claude Code when working with this template repository.

## What This Repo Is

This is a **project template generator**, not a project itself. It contains:
- `create-project.sh` - Interactive script that generates new projects
- `templates/` - Source files copied/transformed during generation

## Repository Structure

```
project-template/
├── create-project.sh              # Main generator script
├── README.md
└── templates/
    ├── core/                      # Always copied (.githooks, .gitignore, .editorconfig)
    ├── backend-go/                # Go backend template
    ├── backend-python/            # Python backend template
    ├── backend-node/              # Node.js backend template
    ├── frontend/                  # Frontend template (npm placeholder)
    ├── infra/                     # Infrastructure (Dockerfiles, Caddyfile, deploy.sh)
    ├── scripts/                   # Dev environment scripts
    │   └── port-allocator.py      # Deterministic port allocation per branch
    ├── docker-compose.dev.yml.tmpl # Dev Docker Compose (database)
    ├── docs/todos/                # TODO tracking structure
    │   ├── README.md              # TODO index template
    │   └── TEMPLATE.md            # TODO file template
    └── claude/skills/             # Claude TODO management skills
        ├── todo-list/             # /todo:list
        ├── todo-start/            # /todo:start
        ├── todo-status/           # /todo:status
        ├── todo-review/           # /todo:review
        ├── todo-pr/               # /todo:pr
        └── todo-merge/            # /todo:merge
```

## How the Generator Works

1. User runs `./create-project.sh my-project`
2. Script prompts for: backend language, frontend yes/no, GitHub org, domain
3. Script creates new directory and:
   - Copies relevant templates based on selections
   - Generates `.githooks/pre-commit` and `pre-push` dynamically
   - Generates `scripts/env.sh`, `scripts/dev.sh`, `scripts/teardown.sh` dynamically
   - Generates root `Makefile` dynamically (with `dev` and `teardown` targets)
   - Generates `CLAUDE.md` dynamically
   - Copies `docker-compose.dev.yml` (if backend), `.claude/skills/`, `docs/todos/`
   - Substitutes `{{VARIABLES}}` in `.tmpl` files
   - Initializes git repo with hooks configured

## Template Conventions

- Files ending in `.tmpl` have variables substituted, then renamed without `.tmpl`
- Variables: `{{PROJECT_NAME}}`, `{{GITHUB_ORG}}`, `{{DOMAIN}}`, `{{BACKEND_LANG}}`
- Non-`.tmpl` files are copied as-is

## Adding a New Backend Language

1. Create `templates/backend-{lang}/` with:
   - `Makefile` with targets: `fmt`, `lint`, `test`, `build`, `run`, `clean`
   - `.github/workflows/backend.yml`
   - Source files for a minimal server with `/health` endpoint
2. Create `templates/infra/Dockerfile-{lang}`
3. Update `create-project.sh`:
   - Add option in backend language menu
   - Handle the new language in file copy logic

## Testing Changes

```bash
# Test the generator
./create-project.sh test-project
cd test-project
make build

# Clean up
rm -rf test-project
```
