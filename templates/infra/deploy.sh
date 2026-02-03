#!/bin/bash
# Deploy to a server

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
error() { echo -e "${RED}error:${NC} $1" >&2; exit 1; }

DEPLOY_TARGET=""
DEPLOY_PATH="/opt/project"
SSH_OPTS=""
INIT_MODE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --init) INIT_MODE=true; shift ;;
        -i) SSH_OPTS="-i $2"; shift 2 ;;
        -*) error "Unknown option: $1" ;;
        *) DEPLOY_TARGET="$1"; shift ;;
    esac
done

if [[ -z "$DEPLOY_TARGET" ]]; then
    echo "Usage: ./deploy.sh user@host [--init] [-i identity_file]"
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

log "Deploying to $DEPLOY_TARGET:$DEPLOY_PATH"

# Test connection
ssh $SSH_OPTS -o ConnectTimeout=10 "$DEPLOY_TARGET" "echo 'Connected'" > /dev/null 2>&1 || error "Cannot connect"

GIT_COMMIT=$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo "unknown")
GIT_BRANCH=$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

log "Commit: $GIT_COMMIT (branch: $GIT_BRANCH)"

# Build frontend if it exists
if [[ -d "$REPO_ROOT/frontend" ]]; then
    log "Building frontend..."
    cd "$REPO_ROOT/frontend"
    [[ -d node_modules ]] || npm install
    npm run build
fi

if $INIT_MODE; then
    log "First-time setup..."

    ssh $SSH_OPTS "$DEPLOY_TARGET" bash <<EOF
        set -euo pipefail
        [[ -d "$DEPLOY_PATH" ]] || { sudo mkdir -p "$DEPLOY_PATH"; sudo chown \$USER:\$USER "$DEPLOY_PATH"; }
EOF

    rsync -avz --delete -e "ssh $SSH_OPTS" \
        --exclude '.git' --exclude 'node_modules' --exclude '.env' \
        --exclude 'backups/' --exclude 'frontend/src' \
        "$REPO_ROOT/" "$DEPLOY_TARGET:$DEPLOY_PATH/"

    ssh $SSH_OPTS "$DEPLOY_TARGET" bash <<'ENDSSH'
        cd /opt/project/infra
        if [[ ! -f .env ]]; then
            cp .env.example .env
            sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$(openssl rand -base64 24 | tr -d '\n/+')|" .env
            sed -i "s|JWT_SECRET=.*|JWT_SECRET=$(openssl rand -base64 32 | tr -d '\n/+')|" .env
            echo "Edit .env to set DOMAIN: nano /opt/project/infra/.env"
        fi
ENDSSH

    log "Setup complete! SSH in and edit .env, then run: make up"
else
    rsync -avz --delete -e "ssh $SSH_OPTS" \
        --exclude '.git' --exclude '.env' --exclude 'backups/' \
        --exclude 'node_modules' --exclude 'frontend/src' \
        "$REPO_ROOT/" "$DEPLOY_TARGET:$DEPLOY_PATH/"

    ssh $SSH_OPTS "$DEPLOY_TARGET" bash <<EOF
        cd "$DEPLOY_PATH/infra"
        export GIT_COMMIT="$GIT_COMMIT" GIT_BRANCH="$GIT_BRANCH" BUILD_TIME="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
        docker compose build
        docker compose up -d --remove-orphans
        docker compose ps
EOF

    log "Deployment complete!"
fi
