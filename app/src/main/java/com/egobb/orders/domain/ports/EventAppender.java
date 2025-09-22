package com.egobb.orders.domain.ports;

import com.egobb.orders.domain.event.TrackingEvent;

public interface EventAppender {
  void append(TrackingEvent event);
}
