package com.egobb.orders.infra;

import com.egobb.orders.Application;
import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;

@SpringBootTest(classes = Application.class, webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class RestIntegrationTest {
	@LocalServerPort
	int port;

	@BeforeAll
	static void setup() {
		RestAssured.baseURI = "http://localhost";
	}

	@Test
	void post_ingest_json_200() {
		given().port(this.port).contentType("application/json").body(
				"{\"event\":[{\"orderId\":\"A1\",\"status\":\"PICKED_UP_AT_WAREHOUSE\",\"eventTs\":\"2025-01-01T10:00:00Z\"}]}")
				.when().post("/order/tracking").then().statusCode(200).body("[0].accepted", equalTo(true));
	}
}
