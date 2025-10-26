package com.egobb.orders.contract.event.consumer;

import com.egobb.orders.contract.event.mapper.TrackingEventMapper;
import com.egobb.orders.domain.service.TrackingService;
import com.egobb.orders.infrastructure.kafka.KafkaTopics;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class TrackingEventConsumer {

	private final TrackingService processor;

	@KafkaListener(topics = KafkaTopics.TRACKING_EVENTS, groupId = "order-tracking-processor", concurrency = "6")
	public void onMessage(TrackingEventMapper.TrackingEventMsg msg) {
		log.info(">>> Consumed from Kafka: {}", msg);
		final var domain = TrackingEventMapper.toDomain(msg);
		this.processor.process(domain);
	}
}
