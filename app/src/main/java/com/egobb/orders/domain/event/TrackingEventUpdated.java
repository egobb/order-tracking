package com.egobb.orders.domain.event;

import com.egobb.orders.domain.model.Status;
import java.time.Instant;

public record TrackingEventUpdated(String orderId, Status status, Instant eventTs)
    implements DomainEvent {}
