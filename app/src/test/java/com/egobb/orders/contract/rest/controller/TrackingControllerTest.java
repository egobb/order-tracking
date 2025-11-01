package com.egobb.orders.contract.rest.controller;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.application.handler.EnqueueTrackingEventCmdHandler;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventDTO;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventsDTO;
import com.egobb.orders.contract.rest.controller.mapper.TrackingEventMapper;
import com.egobb.orders.domain.model.Status;
import java.time.Instant;
import java.util.List;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

public class TrackingControllerTest {

  @Test
  void ingest_maps_and_handles_all_events() {
    // Arrange
    final var mapper = mock(TrackingEventMapper.class);
    final var handler = mock(EnqueueTrackingEventCmdHandler.class);
    final var controller = new TrackingController(mapper, handler);

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

    final var cmd1 = new EnqueueTrackingEventCmd("ORDER-1", Status.OUT_FOR_DELIVERY, dto1.eventTs);
    final var cmd2 = new EnqueueTrackingEventCmd("ORDER-2", Status.DELIVERED, dto2.eventTs);

    when(mapper.toEnqueueCmdList(eventsDTO)).thenReturn(List.of(cmd1, cmd2));

    // Act
    final var response = controller.ingest(eventsDTO);

    // Assert
    final ArgumentCaptor<EnqueueTrackingEventCmd> captor =
        ArgumentCaptor.forClass(EnqueueTrackingEventCmd.class);
    verify(handler, times(2)).handle(captor.capture());
    assertThat(captor.getAllValues()).containsExactly(cmd1, cmd2);
    assertThat(response.getStatusCode().is2xxSuccessful()).isTrue();
  }
}
