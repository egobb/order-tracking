#!/usr/bin/env bash
set -euo pipefail
BASE_URL=${1:-http://localhost:8080}

pass() { echo -e "\033[32m✔ $1\033[0m"; }
fail() { echo -e "\033[31m✘ $1\033[0m"; exit 1; }

# Health
code=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/actuator/health")
[[ "$code" == "200" ]] && pass "Health endpoint up" || fail "Health endpoint failed"

# Ingest JSON
resp=$(curl -s -X POST "$BASE_URL/order/tracking" -H "Content-Type: application/json"   -d '{"event":[{"orderId":"A1","status":"PICKED_UP_AT_WAREHOUSE","eventTs":"2025-01-01T10:00:00Z"}]}' )
echo "$resp" | grep -q '"accepted":true' && pass "JSON ingestion accepted" || fail "JSON ingestion failed"

# Ingest XML
resp=$(curl -s -X POST "$BASE_URL/order/tracking" -H "Content-Type: application/xml"   -d '<events><event><orderId>A2</orderId><status>PICKED_UP_AT_WAREHOUSE</status><eventTs>2025-01-01T10:00:00Z</eventTs></event></events>')
echo "$resp" | grep -q '"accepted":true' && pass "XML ingestion accepted" || fail "XML ingestion failed"

pass "All checks passed!"
