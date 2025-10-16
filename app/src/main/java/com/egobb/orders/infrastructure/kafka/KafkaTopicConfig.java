package com.egobb.orders.infrastructure.kafka;

import org.apache.kafka.clients.admin.NewTopic;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.config.TopicBuilder;

@Configuration
public class KafkaTopicConfig {

  @Bean
  public NewTopic trackingEventsTopic() {
    return TopicBuilder.name(KafkaTopics.TRACKING_EVENTS).partitions(6).build();
  }
}
