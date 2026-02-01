# Frontend Makefile
# Wraps npm commands with standard targets for consistency

.PHONY: lint test build clean help install dev

.DEFAULT_GOAL := help

# =============================================================================
# Hook Setup (DO NOT REMOVE)
# =============================================================================

ensure-hooks:
	@../.githooks/ensure-hooks.sh

# =============================================================================
# Main Targets
# =============================================================================

install: ensure-hooks ## Install dependencies
	npm install

dev: ensure-hooks ## Start development server
	npm run dev

lint: ensure-hooks ## Run linter
	npm run lint

test: ensure-hooks ## Run tests
	# Customize based on your test setup
	# npm test
	@echo "No tests configured"

build: ensure-hooks ## Production build
	npm run build

clean: ## Remove build artifacts
	rm -rf dist node_modules/.cache

# =============================================================================
# Help
# =============================================================================

help: ## Show this help
	@echo "Frontend targets:"
	@echo "  install  - Install dependencies (npm install)"
	@echo "  dev      - Start development server"
	@echo "  lint     - Run ESLint"
	@echo "  test     - Run tests"
	@echo "  build    - Production build"
	@echo "  clean    - Remove build artifacts"
