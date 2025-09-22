package com.egobb.orders.integration;

import static io.restassured.RestAssured.given;
import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.timeout;
import static org.mockito.Mockito.times;

import com.egobb.orders.Application;
import com.egobb.orders.application.service.TrackingProcessor;
import com.egobb.orders.domain.event.TrackingEvent;
import io.restassured.RestAssured;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;
import org.mockito.Captor;
import org.mockito.Mockito;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.SpyBean;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

@Testcontainers
@SpringBootTest(
    classes = Application.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class OrderTrackingIntegrationTest {

  private static final DockerImageName KAFKA_IMAGE = DockerImageName.parse("apache/kafka:3.7.1");

  @Container static final KafkaContainer KAFKA = new KafkaContainer(KAFKA_IMAGE);

  @DynamicPropertySource
  static void kafkaProps(DynamicPropertyRegistry r) {
    r.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
    r.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
  }

  @LocalServerPort int port;

  @SpyBean TrackingProcessor trackingProcessor;

  @Captor ArgumentCaptor<TrackingEvent> eventCaptor;

  @BeforeAll
  static void setup() {
    RestAssured.baseURI = "http://localhost";
  }

  @Test
  void end_to_end_rest_to_kafka_to_processor() {
    // Given: a JSON batch with multiple trackings for different orders
    final var t0 = Instant.parse("2025-01-01T10:00:00Z");
    final String payload =
        """
				{
				  "event": [
				    {"orderId": "A-1", "status": "PICKED_UP_AT_WAREHOUSE", "eventTs": "2025-01-01T10:00:00Z"},
				    {"orderId": "A-1", "status": "DELIVERED", "eventTs": "2025-01-01T10:10:00Z"},
				    {"orderId": "A-1", "status": "OUT_FOR_DELIVERY", "eventTs": "2025-01-01T10:20:00Z"},
				    {"orderId": "B-1", "status": "PICKED_UP_AT_WAREHOUSE", "eventTs": "2025-01-01T10:01:00Z"},
				    {"orderId": "B-1", "status": "DELIVERY_ISSUE", "eventTs": "2025-01-01T10:11:00Z"}
				  ]
				}
				""";

    // When: we call the REST endpoint
    given()
        .port(this.port)
        .contentType("application/json")
        .body(payload)
        .when()
        .post("/order/tracking")
        .then()
        .statusCode(202);

    // Then: processor is invoked once per event
    Mockito.verify(this.trackingProcessor, timeout(10_000).times(5))
        .processOne(any(TrackingEvent.class));

    Mockito.verify(this.trackingProcessor, times(5)).processOne(this.eventCaptor.capture());
    final var processed = this.eventCaptor.getAllValues();

    // Group by orderId
    final Map<String, List<TrackingEvent>> byOrder =
        processed.stream().collect(Collectors.groupingBy(TrackingEvent::orderId));

    // Cardinality
    assertThat(byOrder.get("A-1")).hasSize(3);
    assertThat(byOrder.get("B-1")).hasSize(2);

    // Order preserved per orderId
    assertOrderedByTimestamp(byOrder.get("A-1"));
    assertOrderedByTimestamp(byOrder.get("B-1"));
  }

  private static void assertOrderedByTimestamp(List<TrackingEvent> events) {
    final var sorted =
        events.stream().sorted(Comparator.comparing(TrackingEvent::eventTs)).toList();
    assertThat(events).containsExactlyElementsOf(sorted);
  }
}
