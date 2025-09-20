package com.egobb.orders.domain.ports;

import com.egobb.orders.domain.model.OrderTimeline;
import java.util.Optional;

public interface OrderTimelineRepository {
  Optional<OrderTimeline> findById(String orderId);

  OrderTimeline save(OrderTimeline timeline);
}
