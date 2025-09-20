# Makefile for order-tracking project

COMPOSE = docker compose -f deploy/docker-compose.yml --env-file .env

.PHONY: up down ps logs-db logs-adminer run run-pg test fmt lint seed

## --- Docker Compose commands ---

up: ## Start Postgres + Adminer defined in /deploy/docker-compose.yml
	$(COMPOSE) up -d

down: ## Stop and remove containers + volumes
	$(COMPOSE) down -v

ps: ## List running containers
	$(COMPOSE) ps

logs-db: ## Show logs of Postgres container
	$(COMPOSE) logs -f $(SERVICE_NAME)

logs-adminer: ## Show logs of Adminer container
	$(COMPOSE) logs -f adminer


## --- Application commands ---

run: ## Start the app with in-memory (H2) profile for quick development
	mvn -q -Dspring-boot.run.profiles=dev spring-boot:run

run-pg: ## Start the app against Postgres (requires 'make up' and .env configured)
	mvn -q -Dspring-boot.run.profiles=pg spring-boot:run

test: ## Run all tests
	mvn -q -B verify

fmt: ## Format code with Maven plugin
	mvn -q fmt:format

lint: ## Compile and run checks without executing tests
	mvn -q -DskipTests=true -B -e -U verify

seed: ## Run seed script (if available)
	@./scripts/seed.sh
