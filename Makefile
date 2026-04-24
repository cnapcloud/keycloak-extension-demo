COMPOSE_FILE := docker/compose.yaml
PROJECT_NAME := keycloak-extension-demo
DOCKER_COMPOSE := docker compose -f $(COMPOSE_FILE) -p $(PROJECT_NAME) --project-directory docker

.PHONY: up down up-svc down-svc restart logs ps clean help

up: ## Start containers in background
	$(DOCKER_COMPOSE) up -d || ($(DOCKER_COMPOSE) logs keycloak && exit 1)

down: ## Stop and remove containers (with orphans)
	$(DOCKER_COMPOSE) down --remove-orphans

clean: ## Stop and remove containers, volumes, images, and data directory
	$(DOCKER_COMPOSE) down --remove-orphans --volumes --rmi local
	rm -rf docker/data

up-svc: ## Start a single service, no deps, detached (usage: make up-svc SVC=keycloak)
	$(DOCKER_COMPOSE) up -d --no-deps $(SVC)

down-svc: ## Stop and remove a single service (usage: make down-svc SVC=keycloak)
	$(DOCKER_COMPOSE) rm -sf $(SVC)

restart: ## Restart containers
	$(DOCKER_COMPOSE) down && $(DOCKER_COMPOSE) up -d

logs: ## Stream container logs
	$(DOCKER_COMPOSE) logs -f

ps: ## Show container status
	$(DOCKER_COMPOSE) ps

help: ## Show this help message
	@echo "Usage: make [target]"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-10s %s\n", $$1, $$2}'
