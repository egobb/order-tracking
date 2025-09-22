package com.egobb.orders.infra;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

import com.egobb.orders.Application;
import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.KafkaContainer;
import org.testcontainers.utility.DockerImageName;

@SpringBootTest(
    classes = Application.class,
    webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@Testcontainers
@AutoConfigureMockMvc
public class RestIntegrationTest {

  private static final DockerImageName KAFKA_IMAGE = DockerImageName.parse("apache/kafka:3.7.1");

  @Container static final KafkaContainer KAFKA = new KafkaContainer(KAFKA_IMAGE);

  @DynamicPropertySource
  static void kafkaProps(DynamicPropertyRegistry r) {
    r.add("spring.kafka.bootstrap-servers", KAFKA::getBootstrapServers);
    r.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
  }

  @LocalServerPort int port;

  @BeforeAll
  static void setup() {
    RestAssured.baseURI = "http://localhost";
  }

  @Test
  void post_ingest_json_202() {
    given()
        .port(this.port)
        .contentType("application/json")
        .body(
            "{\"event\":[{\"orderId\":\"A1\",\"status\":\"PICKED_UP_AT_WAREHOUSE\",\"eventTs\":\"2025-01-01T10:00:00Z\"}]}")
        .when()
        .post("/order/tracking")
        .then()
        .statusCode(202)
        .body("[0].accepted", equalTo(true));
  }
}
