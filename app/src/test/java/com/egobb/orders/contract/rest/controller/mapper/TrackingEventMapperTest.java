package com.egobb.orders.contract.rest.controller.mapper;

import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventDTO;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventsDTO;
import com.egobb.orders.domain.model.Status;
import org.junit.jupiter.api.Test;

import java.time.Instant;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class TrackingEventMapperTest {

	private final TrackingEventMapper mapper = new TrackingEventMapper();

	@Test
	void toEnqueueCmdList_maps_all_fields() {
		// Arrange
		final var dto1 = new TrackingEventDTO();
		dto1.orderId = "ORDER-1";
		dto1.status = Status.OUT_FOR_DELIVERY;
		dto1.eventTs = Instant.parse("2025-01-01T10:00:00Z");

		final var dto2 = new TrackingEventDTO();
		dto2.orderId = "ORDER-2";
		dto2.status = Status.DELIVERED;
		dto2.eventTs = Instant.parse("2025-01-01T11:00:00Z");

		final var eventsDTO = new TrackingEventsDTO();
		eventsDTO.event = List.of(dto1, dto2);

		// Act
		final List<EnqueueTrackingEventCmd> cmds = this.mapper.toEnqueueCmdList(eventsDTO);

		// Assert
		assertThat(cmds).hasSize(2);
		assertThat(cmds.get(0).orderId()).isEqualTo("ORDER-1");
		assertThat(cmds.get(0).status()).isEqualTo(Status.OUT_FOR_DELIVERY);
		assertThat(cmds.get(0).eventTs()).isEqualTo(Instant.parse("2025-01-01T10:00:00Z"));
		assertThat(cmds.get(1).orderId()).isEqualTo("ORDER-2");
		assertThat(cmds.get(1).status()).isEqualTo(Status.DELIVERED);
		assertThat(cmds.get(1).eventTs()).isEqualTo(Instant.parse("2025-01-01T11:00:00Z"));
	}
}