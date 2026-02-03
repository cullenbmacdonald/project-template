# Backend Makefile (Go)

.PHONY: lint test build clean help run fmt vet

.DEFAULT_GOAL := help

BUILD_DIR := bin
BINARY := server

GIT_COMMIT := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
BUILD_TIME := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
VERSION ?= dev

ensure-hooks:
	@../.githooks/ensure-hooks.sh

fmt: ensure-hooks ## Format code
	go fmt ./...

vet: ensure-hooks ## Run go vet
	go vet ./...

lint: ensure-hooks ## Run linter
	@if command -v golangci-lint >/dev/null 2>&1; then \
		golangci-lint run; \
	else \
		echo "golangci-lint not installed, running go vet only"; \
		go vet ./...; \
	fi

test: ensure-hooks ## Run tests
	go test -race -v ./...

build: ensure-hooks ## Build the binary
	@mkdir -p $(BUILD_DIR)
	go build -ldflags="-X main.Version=$(VERSION) -X main.CommitHash=$(GIT_COMMIT) -X main.BuildTime=$(BUILD_TIME)" \
		-o $(BUILD_DIR)/$(BINARY) ./cmd/server

run: build ## Run the server
	./$(BUILD_DIR)/$(BINARY)

clean: ## Remove build artifacts
	rm -rf $(BUILD_DIR)

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
