hello from docker

# Project Template

An interactive project template with automated git hooks, CI/CD, and deployment infrastructure.

## Quick Start

```bash
# Clone the template
git clone https://github.com/cullenbmacdonald/project-template.git
cd project-template

# Create a new project
./create-project.sh my-project

# Follow the prompts to choose:
#   - Backend language (Go, Python, Node.js, or none)
#   - Whether to include a frontend
#   - GitHub org/username (optional)
#   - Production domain (optional)
```

## What Gets Generated

```
my-project/
├── Makefile               # Root coordinator
├── .githooks/             # Pre-commit and pre-push hooks
├── .github/workflows/     # CI pipelines (path-filtered)
├── backend/               # If backend selected
│   ├── Makefile
│   └── ...                # Language-specific files
├── frontend/              # If frontend selected
│   ├── Makefile
│   └── package.json
└── infra/                 # If backend selected
    ├── Makefile
    ├── docker-compose.yml
    ├── Dockerfile
    ├── Caddyfile
    ├── deploy.sh
    └── cloud-init.yaml
```

## Features

### Automatic Git Hooks

Hooks are configured automatically on project creation:

- **Pre-commit**: Runs formatters and linters on staged files
- **Pre-push**: Runs tests and builds on changed directories

Only the directories with actual changes are checked.

### Path-Filtered CI

GitHub Actions only run when relevant files change:

- `backend.yml` - Triggers on `backend/**` changes
- `frontend.yml` - Triggers on `frontend/**` changes

### Unified Makefile Interface

Same targets work everywhere:

```bash
make lint      # Lint all components
make test      # Test all components
make build     # Build all components
make deploy    # Deploy to server
```

### Production Infrastructure

The `infra/` directory includes:

- Docker Compose for PostgreSQL + API + Caddy
- Automatic TLS via Let's Encrypt
- Cloud-init for server provisioning
- Deploy script with rsync

## Backend Options

| Language | Framework | Linter |
|----------|-----------|--------|
| Go | stdlib | golangci-lint |
| Python | FastAPI | ruff |
| Node.js | Express + TypeScript | ESLint |

## Frontend

The frontend is a placeholder - set up your preferred framework:

```bash
cd my-project/frontend
npm create vite@latest . -- --template react-ts
```

## Deployment

### First-time Setup

1. Provision a server with `infra/cloud-init.yaml`
2. Deploy with init flag:
   ```bash
   ./infra/deploy.sh user@host --init
   ```
3. SSH in and configure `.env`:
   ```bash
   ssh user@host
   nano /opt/project/infra/.env  # Set DOMAIN
   make up
   ```

### Regular Deployment

```bash
make deploy DEPLOY_HOST=user@host
```

## Template Structure

```
project-template/
├── create-project.sh      # Interactive setup script
├── README.md
└── templates/
    ├── core/              # Always copied
    ├── backend-go/
    ├── backend-python/
    ├── backend-node/
    ├── frontend/
    └── infra/
```

## License

MIT
