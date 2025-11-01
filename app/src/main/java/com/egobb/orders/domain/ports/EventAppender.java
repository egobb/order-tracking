package com.egobb.orders.domain.ports;

import com.egobb.orders.domain.event.DomainEvent;
import java.util.List;

public interface EventAppender {
  void append(List<DomainEvent> event);
}
