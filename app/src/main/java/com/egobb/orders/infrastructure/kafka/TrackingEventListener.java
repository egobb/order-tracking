package com.egobb.orders.infrastructure.kafka;

import com.egobb.orders.application.service.TrackingProcessor;
import com.egobb.orders.infrastructure.mapper.TrackingEventMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@Component
@RequiredArgsConstructor
public class TrackingEventListener {

	private final TrackingProcessor processor;

	@KafkaListener(topics = KafkaTopics.TRACKING_EVENTS, groupId = "order-tracking-processor", concurrency = "6")
	public void onMessage(TrackingEventMapper.TrackingEventMsg msg) {
		log.info(">>> Consumed from Kafka: {}", msg);
		final var domain = TrackingEventMapper.toDomain(msg);
		this.processor.processOne(domain);
	}

}
