# Project Template

A flexible project template with automated quality checks, CI/CD, and deployment infrastructure.

## Key Features

- **Automatic git hooks** - Pre-commit and pre-push hooks run checks without manual setup
- **Unified Makefile interface** - Same targets (`lint`, `test`, `build`) across all components
- **Smart CI** - GitHub Actions only run on changed directories
- **Production-ready infra** - Docker Compose, Caddy reverse proxy, cloud-init provisioning

## Quick Start

```bash
# Clone and rename
git clone <this-repo> my-project
cd my-project

# First build automatically configures git hooks
make build

# Now pre-commit/pre-push hooks are active
git commit -m "My change"  # Runs lint on staged files
git push                   # Runs tests and build on changed files
```

## Structure

```
project/
├── Makefile               # Root coordinator - standard targets
├── .githooks/             # Git hooks (auto-configured)
│   ├── pre-commit         # Lint/format on commit
│   ├── pre-push           # Test/build on push
│   └── ensure-hooks.sh    # Auto-setup script
├── .github/workflows/     # GitHub Actions CI
│   ├── backend.yml        # Backend-specific checks
│   └── frontend.yml       # Frontend-specific checks
├── backend/               # Backend code
│   └── Makefile           # Backend-specific targets
├── frontend/              # Frontend code
│   └── Makefile           # Frontend-specific targets
└── infra/                 # Deployment infrastructure
    ├── Makefile           # Server-side operations
    ├── docker-compose.yml # Production services
    ├── Caddyfile          # Reverse proxy config
    ├── Dockerfile         # Backend container
    ├── cloud-init.yaml    # Server provisioning
    ├── deploy.sh          # Deployment script
    └── .env.example       # Environment template
```

## Makefile Targets

Run from the repo root:

```bash
# Aggregate (all components)
make lint      # Lint backend + frontend
make test      # Test backend + frontend
make build     # Build backend + frontend
make clean     # Clean all artifacts
make install   # Install dependencies

# Component-specific
make lint-backend
make build-frontend

# Deployment
make deploy DEPLOY_HOST=user@host

# Help
make help
```

## Customization

### Adding a New Component

1. Create a directory with a Makefile that has: `lint`, `test`, `build`, `clean`, `install`, `help`
2. Add targets to root Makefile
3. Add path filter to `.githooks/pre-commit` and `.githooks/pre-push`
4. Create `.github/workflows/<component>.yml`

### Changing Tech Stack

The hooks and Makefiles are tech-agnostic shells:
- Backend: Replace Go commands with Python/Node/Rust equivalents
- Frontend: Already uses npm wrapper pattern

### Single-Component Projects

For simple projects without separate backend/frontend:
- Delete unused directories
- Simplify root Makefile to call the single component directly
- Update hooks to check only that directory

## Git Hooks

Hooks are automatically configured on first `make build`, `make test`, or `make lint`.

### Pre-commit (runs on `git commit`)
- Detects which directories have staged changes
- Runs formatters and linters on changed directories
- Auto-adds formatting changes to the commit
- Blocks commit if lint fails

### Pre-push (runs on `git push`)
- Compares local branch to remote
- Runs tests and builds only for changed directories
- Blocks push if tests/build fail

### Manual Setup (if needed)
```bash
git config core.hooksPath .githooks
```

## CI/CD

GitHub Actions run on push/PR to main, filtered by path:
- `backend.yml` - Only runs when `backend/**` changes
- `frontend.yml` - Only runs when `frontend/**` changes

Each workflow runs lint, test, and build in parallel jobs.

## Deployment

### Initial Server Setup

1. Create server with `infra/cloud-init.yaml` as user data
2. Deploy with init flag:
   ```bash
   ./infra/deploy.sh user@host --init
   ```
3. SSH in and configure `.env`
4. Start services:
   ```bash
   cd /opt/project/infra && make up
   ```

### Regular Deployment

```bash
make deploy DEPLOY_HOST=user@host
```

The deploy script:
- Detects which components changed since last deploy
- Only rebuilds changed components
- Updates only what's necessary

## Environment Variables

See `infra/.env.example` for all configuration options.

Required variables:
- `DOMAIN` - Your domain for TLS certificates
- `DB_PASSWORD` - Database password
- `JWT_SECRET` - Authentication secret

## License

MIT
