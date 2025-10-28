package com.egobb.orders.application.command;

import com.egobb.orders.domain.model.Status;
import java.time.Instant;

public record ProcessTrackingEventCmd(String orderId, Status status, Instant eventTs)
    implements Command {}
