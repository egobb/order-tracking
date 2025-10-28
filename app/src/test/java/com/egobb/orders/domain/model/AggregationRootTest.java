package com.egobb.orders.domain.model;

import com.egobb.orders.domain.event.DomainEvent;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

public class AggregationRootTest {

	record DummyEvent(String value, Instant when) implements DomainEvent {
	}

	static class TestRoot extends AggregationRoot {
		void triggerEvent(String value, Instant when) {
			this.addDomainEvent(new AggregationRootTest.DummyEvent(value, when));
		}
	}

	@Test
	void addDomainEvent_accumulates_and_getDomainEvents_returns_copy() {
		final var root = new TestRoot();
		assertThat(root.getDomainEvents()).isEmpty();

		final var t1 = Instant.parse("2024-01-01T10:00:00Z");
		final var t2 = Instant.parse("2024-01-01T11:00:00Z");

		root.triggerEvent("foo", t1);
		root.triggerEvent("bar", t2);

		final var events = root.getDomainEvents();
		assertThat(events).hasSize(2);
		assertThat(((DummyEvent) events.get(0)).value()).isEqualTo("foo");
		assertThat(((DummyEvent) events.get(1)).value()).isEqualTo("bar");
		assertThat(((DummyEvent) events.get(0)).when()).isEqualTo(t1);
		assertThat(((DummyEvent) events.get(1)).when()).isEqualTo(t2);

	}
}
