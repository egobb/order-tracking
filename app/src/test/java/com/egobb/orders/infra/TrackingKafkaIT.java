package com.egobb.orders.infra;

import com.egobb.orders.application.port.in.ProcessTrackingUseCase;
import com.egobb.orders.application.service.TrackingProcessor;
import com.egobb.orders.domain.event.TrackingEvent;
import com.egobb.orders.domain.model.Status;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mockito;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.times;

@Testcontainers
@SpringBootTest
class TrackingKafkaIT {

	// Spin up an ephemeral Kafka broker for this test class
	@Container
	static final KafkaContainer KAFKA = new KafkaContainer(DockerImageName.parse("confluentinc/cp-kafka:7.6.1"));

	// Inject Test containers Kafka bootstrap servers into Spring Kafka properties
	@DynamicPropertySource
	static void kafkaProps(DynamicPropertyRegistry r) {
		r.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
		r.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
	}

	@Autowired
	ProcessTrackingUseCase useCase;

	// Spy on the processor to verify how many times it gets invoked and with which
	// arguments
	@SpyBean
	TrackingProcessor trackingProcessor;

	@Captor
	ArgumentCaptor<TrackingEvent> eventCaptor;

	@Test
	void fanout_to_kafka_and_autoconsume_in_order_per_orderId() {
		// Given: a batch containing multiple orders (A, B) with multiple events each
		final var t0 = Instant.parse("2025-01-01T10:00:00Z");
		final var batch = List.of(
				// Order A (3 events in correct order)
				new TrackingEvent("A-1", Status.PICKED_UP_AT_WAREHOUSE, t0),
				new TrackingEvent("A-1", Status.DELIVERED, t0.plusSeconds(600)),
				new TrackingEvent("A-1", Status.OUT_FOR_DELIVERY, t0.plusSeconds(1200)),
				// Order B (2 events in correct order)
				new TrackingEvent("B-1", Status.PICKED_UP_AT_WAREHOUSE, t0.plusSeconds(60)),
				new TrackingEvent("B-1", Status.DELIVERY_ISSUE, t0.plusSeconds(660)));

		// When: the batch is ingested (service emits domain events -> handler publishes
		// them to Kafka)
		this.useCase.ingestBatch(batch);

		// Then: the Kafka listener (autoconsumer) processes exactly N events
		Mockito.verify(this.trackingProcessor, timeout(10_000).times(batch.size()))
				.processOne(any(TrackingEvent.class));

		// Capture all arguments passed to the processor
		Mockito.verify(this.trackingProcessor, times(batch.size())).processOne(this.eventCaptor.capture());
		final var processed = this.eventCaptor.getAllValues();

		// Group processed events by orderId
		final Map<String, List<TrackingEvent>> byOrder = processed.stream()
				.collect(Collectors.groupingBy(TrackingEvent::orderId));

		// Verify cardinality: order A has 3 events, order B has 2
		assertThat(byOrder.get("A-1")).hasSize(3);
		assertThat(byOrder.get("B-1")).hasSize(2);

		// Verify that each order’s events were processed in the same temporal order as
		// published
		assertOrderedByTimestamp(byOrder.get("A-1"));
		assertOrderedByTimestamp(byOrder.get("B-1"));
	}

	private static void assertOrderedByTimestamp(List<TrackingEvent> events) {
		final var sorted = events.stream().sorted(Comparator.comparing(TrackingEvent::eventTs)).toList();
		assertThat(events).as("Events for a given orderId must be processed in temporal order (FIFO per partition)")
				.containsExactlyElementsOf(sorted);
	}
}
