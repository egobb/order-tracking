package com.egobb.orders.contract.event.mapper;

import static org.assertj.core.api.Assertions.assertThat;

import com.egobb.orders.domain.event.TrackingEventReceived;
import com.egobb.orders.domain.model.Status;
import java.time.Instant;
import org.junit.jupiter.api.Test;

class TrackingEventMapperTest {

  @Test
  void toMsg_maps_all_fields() {
    // Arrange
    final var event =
        new TrackingEventReceived(
            "ORDER-1", Status.DELIVERED, Instant.parse("2025-01-01T12:00:00Z"));

    // Act
    final var msg = TrackingEventMapper.toMsg(event);

    // Assert
    assertThat(msg.orderId()).isEqualTo("ORDER-1");
    assertThat(msg.status()).isEqualTo("DELIVERED");
    assertThat(msg.eventTs()).isEqualTo(Instant.parse("2025-01-01T12:00:00Z"));
    assertThat(msg.schemaVersion()).isEqualTo("v1");
  }

  @Test
  void toDomain_maps_all_fields() {
    // Arrange
    final var msg =
        new TrackingEventMapper.TrackingEventMsg(
            "ORDER-2", "OUT_FOR_DELIVERY", Instant.parse("2025-01-01T13:00:00Z"), "v1");

    // Act
    final var vo = TrackingEventMapper.toDomain(msg);

    // Assert
    assertThat(vo.orderId()).isEqualTo("ORDER-2");
    assertThat(vo.status()).isEqualTo(Status.OUT_FOR_DELIVERY);
    assertThat(vo.eventTs()).isEqualTo(Instant.parse("2025-01-01T13:00:00Z"));
  }
}
