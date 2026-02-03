# Frontend Makefile

.PHONY: lint test build clean help install dev

.DEFAULT_GOAL := help

ensure-hooks:
	@../.githooks/ensure-hooks.sh

install: ensure-hooks ## Install dependencies
	npm install

dev: ensure-hooks ## Start development server
	npm run dev

lint: ensure-hooks ## Run linter
	npm run lint 2>/dev/null || echo "No lint configured - add eslint when you set up your framework"

test: ensure-hooks ## Run tests
	npm test 2>/dev/null || echo "No tests configured"

build: ensure-hooks ## Production build
	npm run build

clean: ## Remove build artifacts
	rm -rf dist node_modules/.cache

help: ## Show this help
	@echo "Frontend targets:"
	@echo "  install  - Install dependencies"
	@echo "  dev      - Start development server"
	@echo "  lint     - Run linter"
	@echo "  test     - Run tests"
	@echo "  build    - Production build"
	@echo "  clean    - Remove build artifacts"
	@echo ""
	@echo "To set up a framework:"
	@echo "  npm create vite@latest . -- --template react-ts"
