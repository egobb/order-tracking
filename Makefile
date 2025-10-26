# Makefile for order-tracking project

COMPOSE = docker compose -f deploy/docker-compose.yml --env-file .env
MVN = ./app/mvnw -f app/pom.xml

.PHONY: up down ps logs-db logs-adminer run run-pg test fmt lint seed

## --- Docker Compose commands ---

up: ## Start Postgres + Adminer + Kafka defined in /deploy/docker-compose.yml
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
	$(MVN) -q -Dspring-boot.run.profiles=local-h2 spring-boot:run

run-pg: ## Start the app against Postgres (requires 'make up' and .env configured)
	$(MVN) -q -Dspring-boot.run.profiles=local-pg spring-boot:run

test: ## Run all tests
	$(MVN) -B verify

fmt: ## Format code with Maven plugin
	$(MVN) -q spotless:apply

lint: ## Compile and run checks without executing tests
	$(MVN) -q -DskipTests=true -B -e -U verify

seed: ## Run seed script (if available)
	@./scripts/seed.sh
