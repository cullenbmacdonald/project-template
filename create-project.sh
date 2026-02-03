#!/bin/bash
# Create a new project from this template
#
# Usage:
#   ./create-project.sh [project-name]
#   ./create-project.sh  # Interactive mode

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/templates"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log() { echo -e "${GREEN}==>${NC} $1"; }
warn() { echo -e "${YELLOW}warning:${NC} $1"; }
error() { echo -e "${RED}error:${NC} $1" >&2; exit 1; }
prompt() { echo -en "${BLUE}?${NC} $1"; }

# =============================================================================
# Collect Variables
# =============================================================================

echo -e "${BOLD}Project Template Setup${NC}"
echo ""

# Project name
if [[ $# -ge 1 ]]; then
    PROJECT_NAME="$1"
else
    prompt "Project name: "
    read -r PROJECT_NAME
fi

if [[ -z "$PROJECT_NAME" ]]; then
    error "Project name is required"
fi

# Validate project name (lowercase, hyphens, no spaces)
if [[ ! "$PROJECT_NAME" =~ ^[a-z][a-z0-9-]*$ ]]; then
    error "Project name must be lowercase, start with a letter, and contain only letters, numbers, and hyphens"
fi

# Check if directory exists
if [[ -d "$PROJECT_NAME" ]]; then
    error "Directory '$PROJECT_NAME' already exists"
fi

# Backend language
echo ""
echo "Backend language:"
echo "  1) Go"
echo "  2) Python"
echo "  3) Node.js"
echo "  4) None (frontend only)"
prompt "Choose [1-4]: "
read -r BACKEND_CHOICE

case $BACKEND_CHOICE in
    1) BACKEND_LANG="go" ;;
    2) BACKEND_LANG="python" ;;
    3) BACKEND_LANG="node" ;;
    4) BACKEND_LANG="none" ;;
    *) error "Invalid choice" ;;
esac

# Frontend
echo ""
prompt "Include frontend? [Y/n]: "
read -r FRONTEND_CHOICE
FRONTEND_CHOICE="${FRONTEND_CHOICE:-y}"
if [[ "$FRONTEND_CHOICE" =~ ^[Yy] ]]; then
    HAS_FRONTEND="yes"
else
    HAS_FRONTEND="no"
fi

# Validate we have at least one component
if [[ "$BACKEND_LANG" == "none" && "$HAS_FRONTEND" == "no" ]]; then
    error "Must have at least a backend or frontend"
fi

# GitHub org (optional)
echo ""
prompt "GitHub org/username (optional, press Enter to skip): "
read -r GITHUB_ORG
GITHUB_ORG="${GITHUB_ORG:-}"

# Domain (optional)
echo ""
prompt "Production domain (optional, press Enter to skip): "
read -r DOMAIN
DOMAIN="${DOMAIN:-example.com}"

# =============================================================================
# Summary
# =============================================================================

echo ""
echo -e "${BOLD}Configuration:${NC}"
echo "  Project name:  $PROJECT_NAME"
echo "  Backend:       $BACKEND_LANG"
echo "  Frontend:      $HAS_FRONTEND"
if [[ -n "$GITHUB_ORG" ]]; then
    echo "  GitHub org:    $GITHUB_ORG"
fi
echo "  Domain:        $DOMAIN"
echo ""

prompt "Create project? [Y/n]: "
read -r CONFIRM
CONFIRM="${CONFIRM:-y}"
if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
    echo "Aborted."
    exit 0
fi

# =============================================================================
# Create Project
# =============================================================================

log "Creating project directory..."
mkdir -p "$PROJECT_NAME"
cd "$PROJECT_NAME"

# Helper to substitute variables in a file
substitute() {
    local file="$1"
    sed -i.bak \
        -e "s|{{PROJECT_NAME}}|$PROJECT_NAME|g" \
        -e "s|{{GITHUB_ORG}}|$GITHUB_ORG|g" \
        -e "s|{{DOMAIN}}|$DOMAIN|g" \
        -e "s|{{BACKEND_LANG}}|$BACKEND_LANG|g" \
        "$file"
    rm -f "$file.bak"
}

# Copy core files
log "Copying core files..."
cp -r "$TEMPLATES_DIR/core/.githooks" .
cp "$TEMPLATES_DIR/core/.gitignore" .
cp "$TEMPLATES_DIR/core/.editorconfig" .
cp "$TEMPLATES_DIR/core/CLAUDE.md.tmpl" CLAUDE.md
substitute CLAUDE.md

# Generate .githooks based on components
log "Configuring git hooks..."
generate_pre_commit() {
    cat > .githooks/pre-commit << 'HOOK_START'
#!/bin/sh
# Pre-commit hook: runs checks for changed directories

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"
STAGED_FILES=$(git diff --cached --name-only)

HOOK_START

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_BACKEND'
BACKEND_CHANGED=$(echo "$STAGED_FILES" | grep -E '^backend/' || true)
HOOK_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_FRONTEND'
FRONTEND_CHANGED=$(echo "$STAGED_FILES" | grep -E '^frontend/' || true)
HOOK_FRONTEND
    fi

    # Build the check condition
    local check_cond=""
    if [[ "$BACKEND_LANG" != "none" ]]; then
        check_cond='[ -z "$BACKEND_CHANGED" ]'
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        if [[ -n "$check_cond" ]]; then
            check_cond="$check_cond && "'[ -z "$FRONTEND_CHANGED" ]'
        else
            check_cond='[ -z "$FRONTEND_CHANGED" ]'
        fi
    fi

    cat >> .githooks/pre-commit << HOOK_CHECK
if $check_cond; then
    echo "No relevant files staged. Skipping checks."
    exit 0
fi

echo "Running pre-commit checks..."
HOOK_CHECK

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_BACKEND_CHECK'

if [ -n "$BACKEND_CHANGED" ]; then
    echo ""
    echo "=== Backend ==="
    cd "$REPO_ROOT/backend"

    echo "Running format..."
    make fmt 2>/dev/null || true

    if ! git diff --quiet; then
        echo "Formatting changes detected, adding to commit..."
        git add -u
    fi

    echo "Running lint..."
    make lint
    if [ $? -ne 0 ]; then
        echo "Backend lint failed. Please fix the issues before committing."
        exit 1
    fi
fi
HOOK_BACKEND_CHECK
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-commit << 'HOOK_FRONTEND_CHECK'

if [ -n "$FRONTEND_CHANGED" ]; then
    echo ""
    echo "=== Frontend ==="
    cd "$REPO_ROOT/frontend"

    if [ -f "tsconfig.json" ]; then
        echo "Running TypeScript check..."
        npx tsc -b
        if [ $? -ne 0 ]; then
            echo "TypeScript check failed. Please fix the issues before committing."
            exit 1
        fi
    fi

    echo "Running lint..."
    make lint
    if [ $? -ne 0 ]; then
        echo "Frontend lint failed. Please fix the issues before committing."
        exit 1
    fi
fi
HOOK_FRONTEND_CHECK
    fi

    cat >> .githooks/pre-commit << 'HOOK_END'

echo ""
echo "Pre-commit checks passed."
HOOK_END

    chmod +x .githooks/pre-commit
}

generate_pre_push() {
    cat > .githooks/pre-push << 'HOOK_START'
#!/bin/sh
# Pre-push hook: runs tests and build for changed directories

set -e

REPO_ROOT="$(git rev-parse --show-toplevel)"

read local_ref local_sha remote_ref remote_sha

if [ "$remote_sha" = "0000000000000000000000000000000000000000" ]; then
    BASE_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
    CHANGED_FILES=$(git diff --name-only "origin/$BASE_BRANCH"..."$local_sha" 2>/dev/null || git diff --name-only "$local_sha")
else
    CHANGED_FILES=$(git diff --name-only "$remote_sha"..."$local_sha")
fi

HOOK_START

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-push << 'HOOK_BACKEND'
BACKEND_CHANGED=$(echo "$CHANGED_FILES" | grep -E '^backend/' || true)
HOOK_BACKEND
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-push << 'HOOK_FRONTEND'
FRONTEND_CHANGED=$(echo "$CHANGED_FILES" | grep -E '^frontend/' || true)
HOOK_FRONTEND
    fi

    # Build the check condition
    local check_cond=""
    if [[ "$BACKEND_LANG" != "none" ]]; then
        check_cond='[ -z "$BACKEND_CHANGED" ]'
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        if [[ -n "$check_cond" ]]; then
            check_cond="$check_cond && "'[ -z "$FRONTEND_CHANGED" ]'
        else
            check_cond='[ -z "$FRONTEND_CHANGED" ]'
        fi
    fi

    cat >> .githooks/pre-push << HOOK_CHECK
if $check_cond; then
    echo "No relevant files in push. Skipping checks."
    exit 0
fi

echo "Running pre-push checks..."
HOOK_CHECK

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> .githooks/pre-push << 'HOOK_BACKEND_CHECK'

if [ -n "$BACKEND_CHANGED" ]; then
    echo ""
    echo "=== Backend Tests ==="
    cd "$REPO_ROOT/backend"

    echo "Running tests..."
    make test
    if [ $? -ne 0 ]; then
        echo "Tests failed. Please fix the issues before pushing."
        exit 1
    fi

    echo ""
    echo "=== Backend Build ==="
    make build
    if [ $? -ne 0 ]; then
        echo "Backend build failed. Please fix the issues before pushing."
        exit 1
    fi
fi
HOOK_BACKEND_CHECK
    fi

    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> .githooks/pre-push << 'HOOK_FRONTEND_CHECK'

if [ -n "$FRONTEND_CHANGED" ]; then
    echo ""
    echo "=== Frontend Build ==="
    cd "$REPO_ROOT/frontend"

    make build
    if [ $? -ne 0 ]; then
        echo "Frontend build failed. Please fix the issues before pushing."
        exit 1
    fi
fi
HOOK_FRONTEND_CHECK
    fi

    cat >> .githooks/pre-push << 'HOOK_END'

echo ""
echo "Pre-push checks passed."
HOOK_END

    chmod +x .githooks/pre-push
}

generate_pre_commit
generate_pre_push

# Copy ensure-hooks.sh
cp "$TEMPLATES_DIR/core/.githooks/ensure-hooks.sh" .githooks/
chmod +x .githooks/ensure-hooks.sh

# Create .github/workflows directory
mkdir -p .github/workflows

# Copy backend files
if [[ "$BACKEND_LANG" != "none" ]]; then
    log "Setting up $BACKEND_LANG backend..."
    cp -r "$TEMPLATES_DIR/backend-$BACKEND_LANG" backend

    # Substitute variables in backend files
    find backend -name "*.tmpl" | while read -r tmpl; do
        mv "$tmpl" "${tmpl%.tmpl}"
        substitute "${tmpl%.tmpl}"
    done

    # Copy workflow
    cp "$TEMPLATES_DIR/backend-$BACKEND_LANG/.github/workflows/backend.yml" .github/workflows/
fi

# Copy frontend files
if [[ "$HAS_FRONTEND" == "yes" ]]; then
    log "Setting up frontend..."
    cp -r "$TEMPLATES_DIR/frontend" frontend

    # Substitute variables
    find frontend -name "*.tmpl" | while read -r tmpl; do
        mv "$tmpl" "${tmpl%.tmpl}"
        substitute "${tmpl%.tmpl}"
    done

    # Copy workflow
    cp "$TEMPLATES_DIR/frontend/.github/workflows/frontend.yml" .github/workflows/
fi

# Copy and configure infra (if we have a backend)
if [[ "$BACKEND_LANG" != "none" ]]; then
    log "Setting up infrastructure..."
    mkdir -p infra

    cp "$TEMPLATES_DIR/infra/Makefile" infra/
    cp "$TEMPLATES_DIR/infra/cloud-init.yaml" infra/
    cp "$TEMPLATES_DIR/infra/deploy.sh" infra/
    chmod +x infra/deploy.sh

    # Copy appropriate Dockerfile
    cp "$TEMPLATES_DIR/infra/Dockerfile-$BACKEND_LANG" infra/Dockerfile

    # Copy and substitute templates
    cp "$TEMPLATES_DIR/infra/docker-compose.yml.tmpl" infra/docker-compose.yml
    cp "$TEMPLATES_DIR/infra/Caddyfile.tmpl" infra/Caddyfile
    cp "$TEMPLATES_DIR/infra/.env.example.tmpl" infra/.env.example

    substitute infra/docker-compose.yml
    substitute infra/Caddyfile
    substitute infra/.env.example

    # Adjust Caddyfile if no frontend
    if [[ "$HAS_FRONTEND" == "no" ]]; then
        # Remove frontend-specific sections from Caddyfile
        sed -i.bak '/# Frontend SPA/,/file_server/d' infra/Caddyfile
        rm -f infra/Caddyfile.bak
    fi
fi

# Generate root Makefile
log "Generating root Makefile..."
generate_makefile() {
    cat > Makefile << 'MAKEFILE_HEADER'
# Root Makefile - Coordinates all subdirectory builds

.PHONY: lint test build clean help install deploy dev

.DEFAULT_GOAL := help

# Configuration
VERSION ?= dev
DEPLOY_HOST ?=

MAKEFILE_HEADER

    # Add phony declarations based on components
    if [[ "$BACKEND_LANG" != "none" ]]; then
        echo ".PHONY: lint-backend test-backend build-backend clean-backend" >> Makefile
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        echo ".PHONY: lint-frontend test-frontend build-frontend clean-frontend install-frontend" >> Makefile
    fi

    echo "" >> Makefile
    echo "# ==============================================================================" >> Makefile
    echo "# Aggregate Targets" >> Makefile
    echo "# ==============================================================================" >> Makefile
    echo "" >> Makefile

    # Lint target
    local lint_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && lint_deps="lint-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && lint_deps="$lint_deps lint-frontend"
    echo "lint: $lint_deps" >> Makefile
    echo '	@echo "All linting complete"' >> Makefile
    echo "" >> Makefile

    # Test target
    local test_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && test_deps="test-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && test_deps="$test_deps test-frontend"
    echo "test: $test_deps" >> Makefile
    echo '	@echo "All tests complete"' >> Makefile
    echo "" >> Makefile

    # Build target
    local build_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && build_deps="build-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && build_deps="$build_deps build-frontend"
    echo "build: $build_deps" >> Makefile
    echo '	@echo "All builds complete"' >> Makefile
    echo "" >> Makefile

    # Clean target
    local clean_deps=""
    [[ "$BACKEND_LANG" != "none" ]] && clean_deps="clean-backend"
    [[ "$HAS_FRONTEND" == "yes" ]] && clean_deps="$clean_deps clean-frontend"
    echo "clean: $clean_deps" >> Makefile
    echo '	@echo "All clean complete"' >> Makefile
    echo "" >> Makefile

    # Install target
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        echo "install: install-frontend" >> Makefile
        echo '	@echo "All dependencies installed"' >> Makefile
    else
        echo "install:" >> Makefile
        echo '	@echo "No dependencies to install"' >> Makefile
    fi
    echo "" >> Makefile

    # Backend targets
    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> Makefile << 'BACKEND_TARGETS'
# ==============================================================================
# Backend Targets
# ==============================================================================

lint-backend:
	$(MAKE) -C backend lint

test-backend:
	$(MAKE) -C backend test

build-backend:
	$(MAKE) -C backend build

clean-backend:
	$(MAKE) -C backend clean

BACKEND_TARGETS
    fi

    # Frontend targets
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        cat >> Makefile << 'FRONTEND_TARGETS'
# ==============================================================================
# Frontend Targets
# ==============================================================================

lint-frontend:
	$(MAKE) -C frontend lint

test-frontend:
	$(MAKE) -C frontend test

build-frontend:
	$(MAKE) -C frontend build

clean-frontend:
	$(MAKE) -C frontend clean

install-frontend:
	$(MAKE) -C frontend install

FRONTEND_TARGETS
    fi

    # Deploy target (only if we have infra)
    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> Makefile << 'DEPLOY_TARGET'
# ==============================================================================
# Deploy Targets
# ==============================================================================

deploy:
ifeq ($(DEPLOY_HOST),)
	$(error DEPLOY_HOST is required. Usage: make deploy DEPLOY_HOST=user@host)
endif
	./infra/deploy.sh $(DEPLOY_HOST)

DEPLOY_TARGET
    fi

    # Dev target
    echo "# ==============================================================================" >> Makefile
    echo "# Development" >> Makefile
    echo "# ==============================================================================" >> Makefile
    echo "" >> Makefile
    echo "dev:" >> Makefile
    echo '	@echo "Starting development servers..."' >> Makefile
    echo '	@echo ""' >> Makefile
    echo '	@echo "Run these in separate terminals:"' >> Makefile
    if [[ "$BACKEND_LANG" != "none" ]]; then
        echo '	@echo "  make -C backend run      # Start backend server"' >> Makefile
    fi
    if [[ "$HAS_FRONTEND" == "yes" ]]; then
        echo '	@echo "  make -C frontend dev     # Start frontend dev server"' >> Makefile
    fi
    echo "" >> Makefile

    # Help target
    cat >> Makefile << 'HELP_TARGET'
# ==============================================================================
# Help
# ==============================================================================

help:
	@echo "Project - Unified Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Aggregate Targets:"
	@echo "  lint      - Lint all components"
	@echo "  test      - Test all components"
	@echo "  build     - Build all components"
	@echo "  clean     - Clean all build artifacts"
	@echo "  install   - Install all dependencies"
	@echo ""
	@echo "Development:"
	@echo "  dev       - Show how to start dev environment"
HELP_TARGET

    if [[ "$BACKEND_LANG" != "none" ]]; then
        cat >> Makefile << 'HELP_DEPLOY'
	@echo ""
	@echo "Deploy:"
	@echo "  deploy DEPLOY_HOST=user@host    - Deploy to server"
HELP_DEPLOY
    fi
}

generate_makefile

# Initialize git repo
log "Initializing git repository..."
git init -q
git config core.hooksPath .githooks

# Create initial commit
git add -A
git commit -q -m "Initial project from template"

# =============================================================================
# Done
# =============================================================================

echo ""
echo -e "${GREEN}Project created successfully!${NC}"
echo ""
echo "Next steps:"
echo "  cd $PROJECT_NAME"
if [[ "$HAS_FRONTEND" == "yes" ]]; then
    echo "  # Set up your frontend framework:"
    echo "  cd frontend && npm create vite@latest . -- --template react-ts"
fi
echo "  make build    # Verify everything works"
echo ""
if [[ -n "$GITHUB_ORG" ]]; then
    echo "To create a GitHub repo:"
    echo "  gh repo create $GITHUB_ORG/$PROJECT_NAME --source=. --push"
fi
