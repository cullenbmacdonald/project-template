# Infrastructure Makefile
# Run these commands on the deployed server

.PHONY: help up down logs restart build clean backup secrets deploy ps

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

up: ## Start all services
	docker compose up -d

down: ## Stop all services
	docker compose down

logs: ## Tail logs from all services
	docker compose logs -f

logs-api: ## Tail API logs
	docker compose logs -f api

restart: ## Restart all services
	docker compose restart

build: ## Build images
	docker compose build

pull: ## Pull latest images
	docker compose pull

ps: ## Show running containers
	docker compose ps

db-shell: ## Open psql shell
	docker compose exec db psql -U app -d app

backup: ## Backup database
	@mkdir -p backups
	docker compose exec -T db pg_dump -U app app > backups/backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "Backup created in ./backups/"

clean: ## Remove stopped containers
	docker compose down --remove-orphans
	docker system prune -f

secrets: ## Generate random secrets
	@echo "DB_PASSWORD=$$(openssl rand -base64 24)"
	@echo "JWT_SECRET=$$(openssl rand -base64 32)"

deploy: pull ## Deploy latest version
	docker compose up -d --remove-orphans
