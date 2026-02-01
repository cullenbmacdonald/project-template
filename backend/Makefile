# Backend Makefile
# Customize for your tech stack (Go, Python, Node.js, etc.)

.PHONY: lint test build clean help install run fmt vet

.DEFAULT_GOAL := help

# Build configuration
BUILD_DIR := bin
BINARY := server

# Version injection (Go example)
GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION ?= dev

# =============================================================================
# Hook Setup (DO NOT REMOVE)
# =============================================================================

ensure-hooks:
	@../.githooks/ensure-hooks.sh

# =============================================================================
# Main Targets
# =============================================================================

install: ensure-hooks ## Install dependencies
	# Go: dependencies managed by go.mod
	# Python: pip install -r requirements.txt
	# Node.js: npm install
	@echo "Dependencies installed"

fmt: ensure-hooks ## Format code
	# Go example:
	go fmt ./...
	# Python: black . or ruff format .
	# Node.js: npm run format

vet: ensure-hooks ## Static analysis
	# Go example:
	go vet ./...
	# Python: mypy . or pyright
	# Node.js: (usually covered by TypeScript in lint)

lint: ensure-hooks ## Run linter
	# Go example:
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed, running go vet only"; \
		go vet ./...; \
	fi
	# Python: ruff check . or flake8
	# Node.js: npm run lint

test: ensure-hooks ## Run tests
	# Go example:
	go test -race -v ./...
	# Python: pytest
	# Node.js: npm test

build: ensure-hooks ## Build the application
	# Go example:
	@mkdir -p $(BUILD_DIR)
	go build -ldflags="-X main.Version=$(VERSION) -X main.CommitHash=$(GIT_COMMIT) -X main.BuildTime=$(BUILD_TIME)" \
		-o $(BUILD_DIR)/$(BINARY) ./cmd/server
	# Python: (no build step usually)
	# Node.js: npm run build

run: build ## Run the application
	./$(BUILD_DIR)/$(BINARY)

clean: ## Remove build artifacts
	rm -rf $(BUILD_DIR)
	# Python: rm -rf __pycache__ .pytest_cache .mypy_cache
	# Node.js: rm -rf dist node_modules/.cache

# =============================================================================
# Help
# =============================================================================

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
