# Infrastructure Makefile
# Run these commands on the deployed server (in /opt/project/infra)

.PHONY: help up down logs restart build clean backup shell secrets deploy ps config

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

# =============================================================================
# Docker Compose Commands
# =============================================================================

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

logs: ## Tail logs from all services
	docker compose logs -f

restart: ## Restart all services
	docker compose restart

build: ## Build images
	docker compose build

pull: ## Pull latest images
	docker compose pull

# =============================================================================
# Individual Services
# =============================================================================

logs-api: ## Tail API logs
	docker compose logs -f api

logs-db: ## Tail database logs
	docker compose logs -f db

restart-api: ## Restart API
	docker compose restart api

# =============================================================================
# Database Operations
# =============================================================================

db-shell: ## Open psql shell to database
	docker compose exec db psql -U app -d app

backup: ## Backup database to ./backups/
	@mkdir -p backups
	docker compose exec -T db pg_dump -U app app > backups/backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup created in ./backups/"

# =============================================================================
# Utilities
# =============================================================================

ps: ## Show running containers
	docker compose ps

config: ## Validate and view compose config
	docker compose config

clean: ## Remove stopped containers and unused images
	docker compose down --remove-orphans
	docker system prune -f

secrets: ## Generate random secrets
	@echo "DB_PASSWORD=$$(openssl rand -base64 24)"
	@echo "JWT_SECRET=$$(openssl rand -base64 32)"

# =============================================================================
# Deployment
# =============================================================================

deploy: pull ## Deploy latest version
	docker compose up -d --remove-orphans
	docker compose logs -f --tail=50

migrate: ## Run database migrations
	docker compose exec api /app/server migrate up
