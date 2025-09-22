package com.egobb.orders.infrastructure.persistence;

import com.egobb.orders.domain.event.TrackingEvent;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.infrastructure.persistence.jpa.TrackingEventEntity;
import com.egobb.orders.infrastructure.persistence.jpa.TrackingEventJpaRepository;
import java.time.Instant;
import org.springframework.stereotype.Component;

@Component
public class EventAppenderAdapter implements EventAppender {
  private final TrackingEventJpaRepository repo;

  public EventAppenderAdapter(TrackingEventJpaRepository repo) {
    this.repo = repo;
  }

  @Override
  public void append(TrackingEvent e) {
    this.repo.save(new TrackingEventEntity(e.orderId(), e.status(), e.eventTs(), Instant.now()));
  }
}
