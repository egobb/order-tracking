# Architecture

- **Style**: hexagonal architecture separated by packages (`domain`, `application`, `infrastructure`).
- **Persistence**: append-only events + projection table for fast reads.
- **Validation**: explicit, auditable state machine in domain layer.
- **Observability**: Spring Actuator + Prometheus metrics.

## Components
- `domain/model`: core types (Status, TrackingEvent, OrderTimeline)
- `domain/service`: state machine
- `domain/ports`: repository and append-only port
- `application/usecase`: batch ingestion use case
- `infrastructure/persistence`: JPA adapters
- `infrastructure/web`: REST controller + DTOs
