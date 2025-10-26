package com.egobb.orders.domain.vo;

import com.egobb.orders.domain.model.Status;

import java.time.Instant;

public record TrackingEventVo(String orderId, Status status, Instant eventTs) {
}
