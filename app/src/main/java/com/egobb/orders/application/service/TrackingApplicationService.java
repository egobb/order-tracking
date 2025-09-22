package com.egobb.orders.application.service;

import com.egobb.orders.application.port.in.ProcessTrackingUseCase;
import com.egobb.orders.application.port.out.PublishDomainEventPort;
import com.egobb.orders.domain.event.TrackingEvent;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class TrackingApplicationService implements ProcessTrackingUseCase {

  private final PublishDomainEventPort domainEventPublisher;

  @Override
  public void ingestBatch(List<TrackingEvent> events) {
    for (final var ev : events) {
      if (ev.orderId() == null || ev.orderId().isBlank()) {
        throw new IllegalArgumentException("orderId is required");
      }
      if (ev.status() == null) {
        throw new IllegalArgumentException("status is required");
      }
      this.domainEventPublisher.publish(ev);
    }
  }
}
