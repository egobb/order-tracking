package com.egobb.orders.application.port.out;

import com.egobb.orders.domain.event.DomainEvent;

public interface PublishDomainEventPort {

  void publish(DomainEvent event);
}
