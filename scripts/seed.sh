#!/usr/bin/env bash
set -euo pipefail

# --- Config (env overrides allowed) ---
COMPOSE_FILE="${COMPOSE_FILE:-deploy/docker-compose.yml}"
SERVICE_NAME="${SERVICE_NAME:-postgres}"       # must match your service in docker-compose
DB_NAME="${DB_NAME:-orders}"
DB_USER="${DB_USER:-orders}"

echo "🚀 Seeding database '${DB_NAME}' using service '${SERVICE_NAME}' ..."

# Use docker compose exec inside the DB container; no TTY needed in CI
docker compose -f "${COMPOSE_FILE}" exec -T "${SERVICE_NAME}" \
  psql -U "${DB_USER}" -d "${DB_NAME}" < scripts/seed.sql

echo "✅ Seeding completed"
