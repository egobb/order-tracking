# Problem Statement (Tech Exercise)

Design a service that receives **order tracking events** (JSON or XML), validates state transitions, and stores the full audit trail. The service must expose an endpoint to ingest events in batches.

## Functional Requirements
- Ingest a list of events with `{orderId, status, eventTs}`.
- Validate transitions:
  - PICKED_UP_AT_WAREHOUSE → OUT_FOR_DELIVERY | DELIVERY_ISSUE
  - OUT_FOR_DELIVERY → DELIVERY_ISSUE | DELIVERED
  - DELIVERY_ISSUE → OUT_FOR_DELIVERY | DELIVERED
  - DELIVERED → (no transitions)
- Keep a full history of events and the last known status per order.
- Support JSON **and** XML payloads (content negotiation).

## Non-Functional Requirements
- Clean architecture (hexagonal), readable and testable.
- Observability: health, metrics, logs.
- Integration tests (Testcontainers for Postgres).
