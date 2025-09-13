package com.egobb.orders.infrastructure.persistence;

import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.ports.OrderTimelineRepository;
import com.egobb.orders.infrastructure.persistence.jpa.OrderEntity;
import com.egobb.orders.infrastructure.persistence.jpa.OrderJpaRepository;
import org.springframework.stereotype.Component;

import java.util.Optional;

@Component
public class OrderTimelineAdapter implements OrderTimelineRepository {
	private final OrderJpaRepository repo;
	public OrderTimelineAdapter(OrderJpaRepository repo) {
		this.repo = repo;
	}

	@Override
	public Optional<OrderTimeline> findById(String orderId) {
		return this.repo.findById(orderId)
				.map(e -> new OrderTimeline(e.getId(), e.getLastStatus(), e.getDeliveredAt()));
	}

	@Override
	public OrderTimeline save(OrderTimeline tl) {
		final OrderEntity e = this.repo.findById(tl.orderId()).orElse(new OrderEntity());
		e.setId(tl.orderId());
		e.setLastStatus(tl.lastStatus());
		e.setDeliveredAt(tl.deliveredAt());
		this.repo.save(e);
		return tl;
	}
}
