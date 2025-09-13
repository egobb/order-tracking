package com.egobb.orders.domain.model;

import java.time.Instant;

public class OrderTimeline {
	private final String orderId;
	private Status lastStatus;
	private Instant deliveredAt;

	public OrderTimeline(String orderId, Status lastStatus, Instant deliveredAt) {
		this.orderId = orderId;
		this.lastStatus = lastStatus;
		this.deliveredAt = deliveredAt;
	}

	public String orderId() {
		return this.orderId;
	}
	public Status lastStatus() {
		return this.lastStatus;
	}
	public Instant deliveredAt() {
		return this.deliveredAt;
	}

	public void apply(Status next, Instant when) {
		this.lastStatus = next;
		if (next.isFinal())
			this.deliveredAt = when;
	}
}
