# Order Tracking Service

A production-style **Spring Boot 3** service that ingests order-tracking events (JSON or XML), validates state transitions, persists the full audit trail, and exposes a projection for quick reads. Built as a portfolio project to showcase clean architecture, observability, testability, and hands-on DevOps.

---

## ✨ Features

- **REST API** to submit tracking events at `/order/tracking` (accepts **JSON** and **XML**).
- **State machine** with auditable transitions:
  - `PICKED_UP_AT_WAREHOUSE` → initial
  - `OUT_FOR_DELIVERY`
  - `DELIVERY_ISSUE`
  - `DELIVERED` → final
- **Append-only audit log** for all events per order, plus a **read-optimized projection** (e.g., `orders`).
- **Validation** of illegal or out-of-order transitions.
- **OpenAPI / Swagger UI** for interactive docs.
- **Observability**: Spring Boot Actuator (health, metrics) and Prometheus scrape endpoint.
- **Solid tests** with JUnit 5, REST Assured and Testcontainers.
- **Docker-ready**: Postgres + Adminer via Docker Compose, runnable locally with Make targets.

---

## 🧩 Architecture

The service follows a **clean / hexagonal** style:

- **Domain**: order event model and business rules for state transitions.
- **Application**: use cases to apply and validate events and to produce the read projection.
- **Adapters**: HTTP controller, persistence adapters (JPA/Hibernate), JSON/XML mappers.
- **Infrastructure**: Spring Boot configuration, database (H2/Postgres), observability and OpenAPI.

**Data shape** (high-level):
- **Audit**: append-only log of events (order id, status, timestamp).
- **Projection**: materialized/current status per order (e.g., `orders`).

This design keeps historical integrity while enabling fast reads and simpler queries.

---

## 🚀 Quick Start

### Prerequisites
- **JDK 17+**
- **Maven 3.9+**
- **Docker** (for Postgres, Adminer and Testcontainers)
- **Make** (optional, quality-of-life shortcuts)

> Copy environment defaults and customize if needed:
>
> ```bash
> cp .env.example .env
> ```

### Option A — Run with in-memory H2

```bash
make run
```

- Swagger UI: <http://localhost:8080/swagger-ui>
- Health: <http://localhost:8080/actuator/health>

### Option B — Run with Postgres (Docker Compose)

```bash
make up         # starts Postgres + Adminer
make run-pg     # runs the Spring Boot app with Postgres profile
```

- Adminer: <http://localhost:8081>
- Swagger UI: <http://localhost:8080/swagger-ui>

> **Without Make:**
> ```bash
> docker compose -f deploy/docker-compose.yml up -d
> mvn spring-boot:run -Dspring-boot.run.profiles=pg
> ```

---

## 🧪 Testing

This project uses **JUnit 5**, **REST Assured** and **Testcontainers**:

```bash
mvn -q clean verify
```

- Unit tests focus on the state machine and validation rules.
- Integration tests spin up containers (e.g., Postgres) for realistic end‑to‑end checks.

---

## 📡 API

### Endpoint
`POST /order/tracking`

Sends one or more events. The service validates transitions and returns, for each event, whether it was accepted.

#### JSON example

```json
{
  "event": [
    {"orderId": "123", "status": "PICKED_UP_AT_WAREHOUSE", "eventTs": "2025-01-01T10:00:00Z"},
    {"orderId": "123", "status": "OUT_FOR_DELIVERY",      "eventTs": "2025-01-01T14:00:00Z"}
  ]
}
```

#### XML example

```xml
<events>
  <event>
    <orderId>123</orderId>
    <status>PICKED_UP_AT_WAREHOUSE</status>
    <eventTs>2025-01-01T10:00:00Z</eventTs>
  </event>
  <event>
    <orderId>123</orderId>
    <status>OUT_FOR_DELIVERY</status>
    <eventTs>2025-01-01T14:00:00Z</eventTs>
  </event>
</events>
```

#### Response

```json
[
  {"orderId": "123", "accepted": true},
  {"orderId": "123", "accepted": true}
]
```

> Explore the API at **Swagger UI**: `/swagger-ui`  
> Raw OpenAPI: `/v3/api-docs`

---

## 🔭 Observability

- **Actuator**: `/actuator/health`, `/actuator/metrics`, `/actuator/info`
- **Prometheus**: `/actuator/prometheus`
- **Structured logs**: application logs include request/response and domain events where useful.

---

## 🧰 Project Structure

```
.
├── app/                # Spring Boot application (controllers, domain, persistence, config)
├── deploy/             # Dockerfile and docker-compose for local infra
├── docs/               # Additional docs, diagrams, ADRs (optional)
├── scripts/            # Helper scripts (linting, db, etc.)
├── tools/grader/       # Local grading/quality utilities (portfolio tooling)
├── .github/            # GitHub Actions workflows, templates
├── .mvn/wrapper/       # Maven Wrapper
├── Makefile            # DX shortcuts (run, run-pg, up, test, etc.)
└── README.md
```

> Tip: If you don't want Make, use the underlying `mvn` and `docker compose` commands directly.

---

## ⚙️ Configuration

Most configuration happens via standard **Spring** properties and `.env` overrides.

Common variables (illustrative; adjust as needed):
- `SERVER_PORT` (default 8080)
- `SPRING_PROFILES_ACTIVE` (e.g., `h2` or `pg`)
- `SPRING_DATASOURCE_URL`, `SPRING_DATASOURCE_USERNAME`, `SPRING_DATASOURCE_PASSWORD`
- `SPRING_JPA_HIBERNATE_DDL_AUTO` (e.g., `update` for local dev)

When using Docker Compose, Postgres and Adminer ports are exposed for local development.

---

## 🛡️ Quality & CI

- **Static analysis & formatting** (via Maven plugins).
- **Conventional commits** and **semantic-release** configuration.
- **GitHub Actions**: build, test, and (optionally) publish artifacts.

---


## 🗺️ Roadmap / Ideas

- **Event-driven scaling**: publish and consume tracking events via a **private Kafka topic** to decouple ingestion from persistence and enable horizontal scaling.
- **CI/CD**: automated deployments to **AWS** (or any cloud) using **Terraform or Pulumi**; add preview environments per PR.
- **API Gateway + policies**: front the service with an API Gateway (rate limits, auth offloading, request/response normalization).
- **Security foundations**: JWT/OAuth2, basic hardening, and **security tests** (authz/authn, input validation, fuzzing).
- **Observability**: ship **Grafana** in Docker with prebuilt dashboards (Actuator/Prometheus metrics, logs, JVM).
- **Architecture (CQRS)**: introduce **CQRS** in `order-tracking` to split write commands and read projections.
- **Distributed cache**: **Redis** for read-side caching of current order status and projections.
- **Load testing**: **JMeter or Gatling** with baseline vs. optimized runs; publish reports in CI.
- **ML module**: simple delay prediction for orders (baseline model + feature pipeline), exposed as an internal endpoint or async enrichment.
- **Tracing**: OpenTelemetry traces and span attributes for domain events.
- **Idempotency**: idempotency keys for event ingestion and deduplication.
- **Read API enhancements**: paging and filtering on read endpoints.
- **Kubernetes**: Helm chart and manifests for a cloud demo.

## 📄 License

Released under the **MIT License**. See `LICENSE` for details.

---

## 🙌 Credits

Made with ❤️ as a personal portfolio project to demonstrate practical, production‑minded engineering.
