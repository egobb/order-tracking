package com.egobb.orders.domain.model;

import com.egobb.orders.domain.event.TrackingEventUpdated;
import com.egobb.orders.domain.vo.TrackingEventVo;

import java.time.Instant;

public class OrderTimeline extends AggregationRoot implements DomainEntity {
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

	public boolean register(TrackingEventVo ev) {
		if (!StateMachine.canTransition(this.lastStatus(), ev.status())) {
			// TODO: Emit functional metrics
			return false;
		}
		this.apply(ev.status(), ev.eventTs());
		this.addDomainEvent(new TrackingEventUpdated(this.orderId, ev.status(), ev.eventTs()));
		return true;
	}

	private void apply(Status next, Instant when) {
		this.lastStatus = next;
		if (next.isFinal())
			this.deliveredAt = when;
	}
}
