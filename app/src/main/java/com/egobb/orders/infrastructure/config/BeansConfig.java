package com.egobb.orders.infrastructure.config;

import com.egobb.orders.application.usecase.IngestTrackingEventsUseCase;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.domain.ports.OrderTimelineRepository;
import com.egobb.orders.domain.service.StateMachine;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class BeansConfig {
	@Bean
	StateMachine stateMachine() {
		return new StateMachine();
	}
	@Bean
	IngestTrackingEventsUseCase useCase(OrderTimelineRepository repo, EventAppender appender, StateMachine sm) {
		return new IngestTrackingEventsUseCase(repo, appender, sm);
	}
}
