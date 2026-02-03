# Backend Makefile (Python)

.PHONY: lint test build clean help run fmt install

.DEFAULT_GOAL := help

VENV := .venv
PYTHON := $(VENV)/bin/python
PIP := $(VENV)/bin/pip

ensure-hooks:
	@../.githooks/ensure-hooks.sh

$(VENV)/bin/activate:
	python3 -m venv $(VENV)
	$(PIP) install --upgrade pip

install: $(VENV)/bin/activate ensure-hooks ## Install dependencies
	$(PIP) install -r requirements.txt
	$(PIP) install -r requirements-dev.txt

fmt: ensure-hooks ## Format code
	@if [ -f $(VENV)/bin/ruff ]; then \
		$(VENV)/bin/ruff format src/; \
	else \
		echo "ruff not installed, skipping format"; \
	fi

lint: ensure-hooks ## Run linter
	@if [ -f $(VENV)/bin/ruff ]; then \
		$(VENV)/bin/ruff check src/; \
	else \
		echo "ruff not installed, skipping lint"; \
	fi

test: ensure-hooks ## Run tests
	@if [ -f $(VENV)/bin/pytest ]; then \
		$(VENV)/bin/pytest; \
	else \
		echo "pytest not installed, skipping tests"; \
	fi

build: ensure-hooks ## Verify the app can start
	@echo "Python apps don't need compilation"
	@echo "Verifying imports..."
	$(PYTHON) -c "import src.main"

run: ## Run the server
	$(PYTHON) -m uvicorn src.main:app --reload --port 8080

clean: ## Remove build artifacts
	rm -rf $(VENV)
	rm -rf __pycache__ .pytest_cache .ruff_cache .mypy_cache
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete 2>/dev/null || true

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
