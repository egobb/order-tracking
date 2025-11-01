package com.egobb.orders.infrastructure.kafka;

import com.egobb.orders.application.port.out.PublishDomainEventPort;
import com.egobb.orders.contract.event.mapper.TrackingEventMapper;
import com.egobb.orders.domain.event.DomainEvent;
import com.egobb.orders.domain.event.TrackingEventReceived;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class TrackingEventDomainHandler implements PublishDomainEventPort {

  private final TrackingEventPublisher publisher;

  @Override
  public void publish(DomainEvent event) {
    this.onDomainEvent(event);
  }

  @EventListener
  public void onDomainEvent(DomainEvent event) {
    if (event instanceof TrackingEventReceived ev) {
      final var msg = TrackingEventMapper.toMsg(ev);
      this.publisher.publish(ev.orderId(), msg);
    }
  }
}
