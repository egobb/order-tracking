package com.egobb.orders.domain.model;

import com.egobb.orders.domain.event.TrackingEventUpdated;
import com.egobb.orders.domain.vo.TrackingEventVo;
import org.junit.jupiter.api.Test;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;

public class OrderTimelineTest {

	@Test
	void register_validTransition_accumulatesDomainEvent_and_updatesState() {
		final var tl = new OrderTimeline("o1", Status.PICKED_UP_AT_WAREHOUSE, null);
		final var ev = new TrackingEventVo("o1", Status.OUT_FOR_DELIVERY, Instant.parse("2024-01-01T10:00:00Z"));

		assertThat(tl.register(ev)).isTrue();

		final var events = tl.getDomainEvents();
		assertThat(events).hasSize(1);
		final var e = (TrackingEventUpdated) events.get(0);
		assertThat(e.orderId()).isEqualTo("o1");
		assertThat(e.status()).isEqualTo(Status.OUT_FOR_DELIVERY);
		assertThat(tl.lastStatus()).isEqualTo(Status.OUT_FOR_DELIVERY);

	}

	@Test
	void register_invalidTransition_returnsFalse_and_noDomainEvents() {
		final var tl = new OrderTimeline("o1", Status.DELIVERED, Instant.parse("2024-01-01T10:00:00Z"));
		final var ev = new TrackingEventVo("o1", Status.OUT_FOR_DELIVERY, Instant.parse("2024-01-01T12:00:00Z"));

		assertThat(tl.register(ev)).isFalse();
		assertThat(tl.getDomainEvents()).isEmpty();
		assertThat(tl.lastStatus()).isEqualTo(Status.DELIVERED);
	}
}
