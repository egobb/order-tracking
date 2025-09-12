# Order Tracking Service

A Spring Boot 3 service that ingests order tracking events (JSON or XML), validates state transitions, and persists the full audit trail.  
This project is designed as a **portfolio piece** to demonstrate clean architecture, auditability, observability, and production-ready practices (Docker, Testcontainers, GitHub Actions).

---

## ✨ Features
- REST API with **JSON** and **XML** support (`/order/tracking`).
- Validates state transitions with a simple, auditable **state machine**:
    - `RECOGIDO_EN_ALMACEN` (Picked up at warehouse) → initial.
    - `EN_REPARTO` (Out for delivery).
    - `INCIDENCIA_EN_ENTREGA` (Delivery issue).
    - `ENTREGADO` (Delivered) → final.
- Audit log of all received events per order.
- Append-only persistence with projection table (`orders`).
- Observable with **Actuator**, **Prometheus metrics**, and structured logs.
- Integration and unit tests with **JUnit 5** and **Testcontainers**.

---

## 🚀 Quick Start

### Prerequisites
- JDK 17+
- Maven 3.9+
- Docker (for Postgres & Testcontainers)
- Make (optional, for shortcuts)

### Run with in-memory H2
```bash
make run
```

### Run with Postgres
```bash
make up        # start postgres + adminer
make run-pg    # run Spring Boot with Postgres profile
```

Adminer UI: [http://localhost:8081](http://localhost:8081)  
Swagger UI: [http://localhost:8080/swagger-ui](http://localhost:8080/swagger-ui)

---

## 🧪 Example Request

**POST** `/order/tracking`

JSON:
```json
{
  "event": [
    {"orderId": "123", "status": "RECOGIDO_EN_ALMACEN", "eventTs": "2025-01-01T10:00:00Z"},
    {"orderId": "123", "status": "EN_REPARTO", "eventTs": "2025-01-01T14:00:00Z"}
  ]
}
```

XML:
```xml
<events>
  <event>
    <orderId>123</orderId>
    <status>RECOGIDO_EN_ALMACEN</status>
    <eventTs>2025-01-01T10:00:00Z</eventTs>
  </event>
  <event>
    <orderId>123</orderId>
    <status>EN_REPARTO</status>
    <eventTs>2025-01-01T14:00:00Z</eventTs>
  </event>
</events>
```

Response:
```json
[
  {"orderId": "123", "accepted": true},
  {"orderId": "123", "accepted": true}
]
```

---

## 📊 Observability
- `/actuator/health` → health checks
- `/actuator/metrics` → Micrometer metrics
- `/actuator/prometheus` → scrape endpoint

---

## 🧰 Tech Stack
- **Java 17**, **Spring Boot 3**
- **Spring Web**, **Validation**
- **Spring Data JPA** with **H2** and **Postgres**
- **Jackson JSON** + **Jackson XML**
- **Springdoc OpenAPI** (Swagger)
- **JUnit 5**, **REST Assured**, **Testcontainers**
- **Docker Compose** (Postgres + Adminer)
- **Makefile** for DX

---

## ✅ Evaluation Criteria (as portfolio piece)
- **Architecture:** clean, hexagonal, domain-driven boundaries.
- **Code Quality:** readability, SOLID principles, error handling.
- **Correctness:** proper validation, tests covering edge cases.
- **Operability:** Docker-ready, health checks, easy to run.
- **Observability:** logs, metrics, optional tracing.

---

## 📜 License
This project is released under the MIT License.  
