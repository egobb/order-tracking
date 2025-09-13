package com.egobb.orders.infrastructure.persistence.jpa;

import com.egobb.orders.domain.model.Status;
import jakarta.persistence.*;

import java.time.Instant;

@Entity
@Table(name = "tracking_events")
public class TrackingEventEntity {
	@Id
	@GeneratedValue(strategy = GenerationType.IDENTITY)
	private Long id;
	private String orderId;
	@Enumerated(EnumType.STRING)
	private Status status;
	private Instant eventTs;
	private Instant ingestedAt;

	public TrackingEventEntity() {
	}
	public TrackingEventEntity(String orderId, Status status, Instant eventTs, Instant ingestedAt) {
		this.orderId = orderId;
		this.status = status;
		this.eventTs = eventTs;
		this.ingestedAt = ingestedAt;
	}
}
