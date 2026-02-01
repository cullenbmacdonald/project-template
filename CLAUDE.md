# CLAUDE.md

This file provides guidance to Claude Code when working with this codebase.

## Project Structure

```
project/
├── Makefile               # Root coordinator - aggregates all components
├── .githooks/             # Git hooks (auto-configured on first build)
├── .github/workflows/     # GitHub Actions CI (path-filtered per component)
├── backend/               # Backend code (customize for your stack)
├── frontend/              # Frontend code (npm-based)
└── infra/                 # Deployment infrastructure
```

## Common Commands

From the repo root:

```bash
make lint      # Lint all components
make test      # Test all components
make build     # Build all components
make clean     # Clean all artifacts
make help      # Show all targets
```

## Git Hooks

Hooks are automatically configured on first `make build`, `make test`, or `make lint`.

- **Pre-commit**: Runs lint on staged files, auto-adds formatting changes
- **Pre-push**: Runs tests and build on changed directories

## Code Style

- Follow the conventions of the specific tech stack in use
- Ensure code passes `make lint` before committing
- Tests should pass before pushing

## Adding New Components

1. Create a new directory with a Makefile containing: `lint`, `test`, `build`, `clean`, `help`
2. Add targets to root Makefile
3. Update `.githooks/pre-commit` and `.githooks/pre-push` with new path patterns
4. Create `.github/workflows/<component>.yml` with path filters

## Deployment

- `make deploy DEPLOY_HOST=user@host` - Deploy to server
- First-time: `./infra/deploy.sh user@host --init`
- Server config: `/opt/project/infra/.env`
