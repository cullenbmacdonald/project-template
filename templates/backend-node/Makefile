# Backend Makefile (Node.js)

.PHONY: lint test build clean help run fmt install

.DEFAULT_GOAL := help

ensure-hooks:
	@../.githooks/ensure-hooks.sh

install: ensure-hooks ## Install dependencies
	npm install

fmt: ensure-hooks ## Format code
	npm run format 2>/dev/null || echo "No format script configured"

lint: ensure-hooks ## Run linter
	npm run lint

test: ensure-hooks ## Run tests
	npm test 2>/dev/null || echo "No tests configured"

build: ensure-hooks ## Build the application
	npm run build

run: ## Run the server
	npm run dev

clean: ## Remove build artifacts
	rm -rf dist node_modules/.cache

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
