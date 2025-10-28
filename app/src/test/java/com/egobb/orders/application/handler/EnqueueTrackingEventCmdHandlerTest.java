package com.egobb.orders.application.handler;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.application.mapper.TrackingEventMapper;
import com.egobb.orders.application.port.out.PublishDomainEventPort;
import com.egobb.orders.domain.event.TrackingEventReceived;
import com.egobb.orders.domain.model.Status;
import java.time.Instant;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

@ExtendWith(MockitoExtension.class)
class EnqueueTrackingEventCmdHandlerTest {

  @Mock PublishDomainEventPort publisher;
  @Mock TrackingEventMapper mapper;

  @InjectMocks EnqueueTrackingEventCmdHandler handler;

  @Test
  void handle_maps_and_publishes_event() {
    // Arrange
    final var cmd =
        new EnqueueTrackingEventCmd(
            "ORDER-1", Status.DELIVERED, Instant.parse("2025-01-01T12:00:00Z"));
    final var event =
        new TrackingEventReceived(
            "ORDER-1", Status.DELIVERED, Instant.parse("2025-01-01T12:00:00Z"));

    when(this.mapper.toDomain(cmd)).thenReturn(event);

    // Act
    this.handler.handle(cmd);

    // Assert
    verify(this.mapper).toDomain(cmd);
    verify(this.publisher).publish(event);
  }
}
