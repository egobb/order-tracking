package com.egobb.orders.infrastructure.persistence;

import com.egobb.orders.domain.event.DomainEvent;
import com.egobb.orders.domain.event.TrackingEventUpdated;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.infrastructure.persistence.jpa.TrackingEventEntity;
import com.egobb.orders.infrastructure.persistence.jpa.TrackingEventJpaRepository;
import org.springframework.stereotype.Component;

import java.time.Instant;
import java.util.List;

@Component
public class EventAppenderAdapter implements EventAppender {
	private final TrackingEventJpaRepository repo;

	public EventAppenderAdapter(TrackingEventJpaRepository repo) {
		this.repo = repo;
	}

	@Override
	public void append(List<DomainEvent> events) {
		for (final DomainEvent e : events) {
			if (!(e instanceof TrackingEventUpdated event)) {
				continue;
			}
			this.repo.save(new TrackingEventEntity(event.orderId(), event.status(), event.eventTs(), Instant.now()));
		}
	}
}
