# Root Makefile - Coordinates all subdirectory builds
#
# Usage:
#   make lint       - Lint backend + frontend
#   make test       - Test backend + frontend
#   make build      - Build backend + frontend
#   make deploy     - Deploy to server
#   make help       - Show all targets

.PHONY: lint test build clean help
.PHONY: lint-backend lint-frontend
.PHONY: test-backend test-frontend
.PHONY: build-backend build-frontend
.PHONY: clean-backend clean-frontend
.PHONY: install install-frontend
.PHONY: deploy dev

# Configuration
VERSION ?= dev
DEPLOY_HOST ?=

.DEFAULT_GOAL := help

# =============================================================================
# Aggregate Targets
# =============================================================================

lint: lint-backend lint-frontend
	@echo "All linting complete"

test: test-backend test-frontend
	@echo "All tests complete"

build: build-backend build-frontend
	@echo "All builds complete"

clean: clean-backend clean-frontend
	@echo "All clean complete"

install: install-frontend
	@echo "All dependencies installed"

# =============================================================================
# Backend Targets
# =============================================================================

lint-backend:
	$(MAKE) -C backend lint

test-backend:
	$(MAKE) -C backend test

build-backend:
	$(MAKE) -C backend build

clean-backend:
	$(MAKE) -C backend clean

# =============================================================================
# Frontend Targets
# =============================================================================

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

# =============================================================================
# Deploy Targets
# =============================================================================

deploy:
ifeq ($(DEPLOY_HOST),)
	$(error DEPLOY_HOST is required. Usage: make deploy DEPLOY_HOST=user@host)
endif
	./infra/deploy.sh $(DEPLOY_HOST)

# =============================================================================
# Development
# =============================================================================

dev:
	@echo "Starting development servers..."
	@echo ""
	@echo "Run these in separate terminals:"
	@echo "  make -C backend run      # Start backend server"
	@echo "  make -C frontend dev     # Start frontend dev server"

# =============================================================================
# Help
# =============================================================================

help:
	@echo "Project - Unified Build System"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Aggregate Targets (run on all components):"
	@echo "  lint      - Lint backend + frontend"
	@echo "  test      - Test backend + frontend"
	@echo "  build     - Build backend + frontend"
	@echo "  clean     - Clean all build artifacts"
	@echo "  install   - Install all dependencies"
	@echo ""
	@echo "Component Targets:"
	@echo "  lint-backend, test-backend, build-backend"
	@echo "  lint-frontend, test-frontend, build-frontend"
	@echo ""
	@echo "Deploy:"
	@echo "  deploy DEPLOY_HOST=user@host    - Deploy to server"
	@echo ""
	@echo "Development:"
	@echo "  dev       - Show how to start dev environment"
	@echo ""
	@echo "Subdirectory Help:"
	@echo "  make -C backend help"
	@echo "  make -C frontend help"
	@echo "  make -C infra help"
