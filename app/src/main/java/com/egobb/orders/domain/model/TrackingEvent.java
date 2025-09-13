package com.egobb.orders.domain.model;

import java.time.Instant;

public record TrackingEvent(String orderId, Status status, Instant eventTs) {
}
