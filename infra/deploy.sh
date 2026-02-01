#!/bin/bash
# Deploy to a server
#
# Usage:
#   ./deploy.sh user@host [--init] [-i identity_file]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}warning:${NC} $1"; }
error() { echo -e "${RED}error:${NC} $1" >&2; exit 1; }

# Configuration
DEPLOY_TARGET="${DEPLOY_HOST:-}"
DEPLOY_PATH="${DEPLOY_PATH:-/opt/project}"
SSH_IDENTITY="${SSH_IDENTITY:-}"
INIT_MODE=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --init)
            INIT_MODE=true
            shift
            ;;
        -i)
            SSH_IDENTITY="$2"
            shift 2
            ;;
        -*)
            error "Unknown option: $1"
            ;;
        *)
            DEPLOY_TARGET="$1"
            shift
            ;;
    esac
done

if [[ -z "$DEPLOY_TARGET" ]]; then
    echo "Usage: ./deploy.sh user@host [--init] [-i identity_file]"
    echo ""
    echo "Options:"
    echo "  --init          First-time setup (create .env, generate secrets)"
    echo "  -i FILE         SSH identity file (private key)"
    echo ""
    echo "Environment variables:"
    echo "  DEPLOY_HOST     Default SSH target"
    echo "  DEPLOY_PATH     Remote path (default: /opt/project)"
    echo "  SSH_IDENTITY    Default SSH identity file"
    echo ""
    echo "Examples:"
    echo "  ./deploy.sh deploy@1.2.3.4 --init -i ~/.ssh/mykey"
    echo "  ./deploy.sh deploy@example.com"
    exit 1
fi

# Build SSH options
SSH_OPTS=""
if [[ -n "$SSH_IDENTITY" ]]; then
    SSH_OPTS="-i $SSH_IDENTITY"
fi

# Get the repo root (parent of infra/)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log "Deploying to $DEPLOY_TARGET:$DEPLOY_PATH"

# Test SSH connection
log "Testing SSH connection..."
if ! ssh $SSH_OPTS -o ConnectTimeout=10 "$DEPLOY_TARGET" "echo 'SSH connection OK'" > /dev/null 2>&1; then
    error "Cannot connect to $DEPLOY_TARGET"
fi

# Get local git info
GIT_COMMIT_SHORT=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

# Check if working directory is dirty
IS_DIRTY=false
if ! git -C "$REPO_ROOT" diff --quiet 2>/dev/null || ! git -C "$REPO_ROOT" diff --cached --quiet 2>/dev/null; then
    IS_DIRTY=true
fi

if $IS_DIRTY; then
    GIT_COMMIT="${GIT_COMMIT_SHORT}-dirty"
else
    GIT_COMMIT="${GIT_COMMIT_SHORT}"
fi

log "Local commit: $GIT_COMMIT (branch: $GIT_BRANCH)"

# Build frontend
build_frontend() {
    log "Building frontend..."

    pushd "$REPO_ROOT/frontend" > /dev/null

    if [[ ! -d "node_modules" ]]; then
        log "Installing frontend dependencies..."
        npm install || error "npm install failed"
    fi

    npm run build || error "npm run build failed"

    if [[ ! -f "dist/index.html" ]]; then
        error "Frontend build failed: dist/index.html not found"
    fi

    log "Frontend build complete: $(ls dist/ | wc -l | tr -d ' ') files"

    popd > /dev/null
}

if $INIT_MODE; then
    log "Running first-time setup..."

    # Build frontend
    build_frontend

    # Create directory and sync files
    ssh $SSH_OPTS "$DEPLOY_TARGET" bash <<EOF
        set -euo pipefail

        if [[ ! -d "$DEPLOY_PATH" ]]; then
            sudo mkdir -p "$DEPLOY_PATH"
            sudo chown \$USER:\$USER "$DEPLOY_PATH"
        fi
EOF

    # Sync files using rsync
    log "Syncing files..."
    rsync -avz --delete \
        -e "ssh $SSH_OPTS" \
        --exclude '.git' \
        --exclude 'node_modules' \
        --exclude '.github' \
        --exclude '.env' \
        --exclude 'backups/' \
        --exclude 'CLAUDE.md' \
        --exclude '.claude/' \
        --exclude '/dist/' \
        --exclude 'backend/bin' \
        --exclude 'frontend/src' \
        --exclude 'frontend/node_modules' \
        --exclude 'frontend/*.json' \
        --exclude 'frontend/*.ts' \
        --exclude 'frontend/*.js' \
        "$REPO_ROOT/" "$DEPLOY_TARGET:$DEPLOY_PATH/"

    # Setup environment file
    ssh $SSH_OPTS "$DEPLOY_TARGET" bash <<'ENDSSH'
        set -euo pipefail
        cd /opt/project/infra

        if [[ ! -f .env ]]; then
            echo "Creating .env from template..."
            cp .env.example .env

            # Generate secrets
            DB_PASS=$(openssl rand -base64 24 | tr -d '\n/+')
            JWT=$(openssl rand -base64 32 | tr -d '\n/+')

            sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
            sed -i "s|JWT_SECRET=.*|JWT_SECRET=$JWT|" .env

            echo ""
            echo "=========================================="
            echo "IMPORTANT: Edit .env to set your domain:"
            echo "  nano /opt/project/infra/.env"
            echo "=========================================="
        fi
ENDSSH

    log "First-time setup complete!"
    echo ""
    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. SSH into the server: ssh $SSH_OPTS $DEPLOY_TARGET"
    echo "  2. Edit the environment file: nano $DEPLOY_PATH/infra/.env"
    echo "  3. Set your DOMAIN and review other settings"
    echo "  4. Start services: cd $DEPLOY_PATH/infra && make up"

else
    # Regular deployment (update)

    # Build frontend
    build_frontend

    # Sync files
    log "Syncing files..."
    rsync -avz --delete \
        -e "ssh $SSH_OPTS" \
        --exclude '.git' \
        --exclude '.env' \
        --exclude 'backups/' \
        --exclude '.github' \
        --exclude 'CLAUDE.md' \
        --exclude '.claude/' \
        --exclude '/dist/' \
        --exclude 'backend/bin' \
        --exclude 'frontend/src' \
        --exclude 'frontend/node_modules' \
        --exclude 'frontend/*.json' \
        --exclude 'frontend/*.ts' \
        --exclude 'frontend/*.js' \
        "$REPO_ROOT/" "$DEPLOY_TARGET:$DEPLOY_PATH/"

    BUILD_TIME=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    log "Deploying services..."
    ssh $SSH_OPTS "$DEPLOY_TARGET" bash <<EOF
        set -euo pipefail
        cd "$DEPLOY_PATH/infra"

        if [[ ! -f .env ]]; then
            echo "Error: .env file not found. Run with --init first."
            exit 1
        fi

        # Build and deploy with version info
        export GIT_COMMIT="$GIT_COMMIT"
        export GIT_BRANCH="$GIT_BRANCH"
        export BUILD_TIME="$BUILD_TIME"

        echo "Building Docker images..."
        docker compose build

        docker compose up -d --remove-orphans

        echo ""
        docker compose ps
EOF

    log "Deployment complete!"
    echo ""
    echo "View logs: ssh $SSH_OPTS $DEPLOY_TARGET 'cd $DEPLOY_PATH/infra && docker compose logs -f'"
fi
