package com.egobb.orders.application.service;

import com.egobb.orders.domain.event.TrackingEvent;
import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.domain.ports.OrderTimelineRepository;
import com.egobb.orders.domain.service.StateMachine;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.Optional;

@Service
@Slf4j
public class TrackingProcessor {
	private final OrderTimelineRepository repository;
	private final EventAppender appender;
	private final StateMachine sm;

	public TrackingProcessor(OrderTimelineRepository repository, EventAppender appender, StateMachine sm) {
		this.repository = repository;
		this.appender = appender;
		this.sm = sm;
	}

	public void processOne(TrackingEvent e) {
		log.info(">>> Processing event: {}", e);
		final Optional<OrderTimeline> maybe = this.repository.findById(e.orderId());
		final OrderTimeline tl = maybe.orElse(new OrderTimeline(e.orderId(), null, null));
		if (!this.sm.canTransition(tl.lastStatus(), e.status())) {
			// TODO: Emit functional metrics
			return;
		}
		tl.apply(e.status(), e.eventTs());
		this.repository.save(tl);
		this.appender.append(e);
	}

}
