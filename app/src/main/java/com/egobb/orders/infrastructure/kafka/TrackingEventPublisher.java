package com.egobb.orders.infrastructure.kafka;

import com.egobb.orders.contract.event.mapper.TrackingEventMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@Component
@RequiredArgsConstructor
public class TrackingEventPublisher {

	private final KafkaTemplate<String, TrackingEventMapper.TrackingEventMsg> template;

	public void publish(String key, TrackingEventMapper.TrackingEventMsg msg) {
		this.template.send(KafkaTopics.TRACKING_EVENTS, key, msg);
	}
}
