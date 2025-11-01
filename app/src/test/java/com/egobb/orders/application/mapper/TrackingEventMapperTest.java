package com.egobb.orders.application.mapper;

import static org.assertj.core.api.Assertions.assertThat;

import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.application.command.ProcessTrackingEventCmd;
import com.egobb.orders.domain.model.Status;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.mapstruct.factory.Mappers;

public class TrackingEventMapperTest {

  private final TrackingEventMapper mapper = Mappers.getMapper(TrackingEventMapper.class);

  @Test
  void toDomain_maps_EnqueueTrackingEventCmd_to_TrackingEventReceived() {
    // Arrange
    final var cmd =
        new EnqueueTrackingEventCmd(
            "ORDER-1", Status.DELIVERED, Instant.parse("2025-01-01T12:00:00Z"));

    // Act
    final var event = this.mapper.toDomain(cmd);

    // Assert
    assertThat(event.orderId()).isEqualTo("ORDER-1");
    assertThat(event.status()).isEqualTo(Status.DELIVERED);
    assertThat(event.eventTs()).isEqualTo(Instant.parse("2025-01-01T12:00:00Z"));
  }

  @Test
  void toDomain_maps_ProcessTrackingEventCmd_to_TrackingEventVo() {
    // Arrange
    final var cmd =
        new ProcessTrackingEventCmd(
            "ORDER-2", Status.OUT_FOR_DELIVERY, Instant.parse("2025-01-01T13:00:00Z"));

    // Act
    final var vo = this.mapper.toDomain(cmd);

    // Assert
    assertThat(vo.orderId()).isEqualTo("ORDER-2");
    assertThat(vo.status()).isEqualTo(Status.OUT_FOR_DELIVERY);
    assertThat(vo.eventTs()).isEqualTo(Instant.parse("2025-01-01T13:00:00Z"));
  }
}
