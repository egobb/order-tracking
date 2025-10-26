package com.egobb.orders.domain.service;

import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.domain.ports.OrderTimelineRepository;
import com.egobb.orders.domain.vo.TrackingEventVo;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Slf4j
public class TrackingService {
	private final OrderTimelineRepository repository;
	private final EventAppender appender;

	public TrackingService(OrderTimelineRepository repository, EventAppender appender) {
		this.repository = repository;
		this.appender = appender;
	}

	public OrderTimeline process(TrackingEventVo e) {
		log.info(">>> Processing event: {}", e);
		final Optional<OrderTimeline> maybe = this.repository.findById(e.orderId());
		final OrderTimeline tl = maybe.orElse(new OrderTimeline(e.orderId(), null, null));
		if (tl.register(e)) {
			this.repository.save(tl);
			this.appender.append(tl.getDomainEvents());
		}
		return tl;
	}
}
