package com.egobb.orders.infrastructure.mapper;

import com.egobb.orders.domain.event.TrackingEvent;
import com.egobb.orders.domain.model.Status;

import java.time.Instant;

public class TrackingEventMapper {

	private TrackingEventMapper() {
	}

	public record TrackingEventMsg(String orderId, String status, Instant eventTs, String schemaVersion) {
	}

	public static TrackingEventMsg toMsg(TrackingEvent ev) {
		return new TrackingEventMsg(ev.orderId(), ev.status().toString(), ev.eventTs(), "v1");
	}

	public static TrackingEvent toDomain(TrackingEventMsg msg) {
		return new TrackingEvent(msg.orderId(), Status.fromString(msg.status()), msg.eventTs());
	}

}
