.PHONY: up down

up:
	docker compose -f deploy/docker-compose.yml up -d

down:
	docker compose -f deploy/docker-compose.yml down -v
<<<<<<< HEAD

# Run Spring Boot app with default profile (H2 in-memory)
run:
	./mvn spring-boot:run

# Run Spring Boot app with Postgres profile (requires docker compose up)
run-pg:
	./mvn spring-boot:run -Dspring-boot.run.profiles=pg
=======
>>>>>>> main
