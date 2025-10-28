package com.egobb.orders.contract.event.consumer;

import com.egobb.orders.contract.event.mapper.TrackingEventMapper;
import com.egobb.orders.domain.model.Status;
import com.egobb.orders.domain.service.TrackingService;
import com.egobb.orders.domain.vo.TrackingEventVo;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.time.Instant;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;

public class TrackingEventConsumerTest {

	@Test
	void onMessage_maps_and_processes_event() {
		// Arrange
		final TrackingService processor = mock(TrackingService.class);
		final TrackingEventConsumer consumer = new TrackingEventConsumer(processor);

		final var msg = new TrackingEventMapper.TrackingEventMsg("ORDER-1", "DELIVERED",
				Instant.parse("2025-01-01T12:00:00Z"), "v1");

		// Act
		consumer.onMessage(msg);

		// Assert
		final ArgumentCaptor<TrackingEventVo> captor = ArgumentCaptor.forClass(TrackingEventVo.class);
		verify(processor).process(captor.capture());
		final TrackingEventVo vo = captor.getValue();
		assertThat(vo.orderId()).isEqualTo("ORDER-1");
		assertThat(vo.status()).isEqualTo(Status.DELIVERED);
		assertThat(vo.eventTs()).isEqualTo(Instant.parse("2025-01-01T12:00:00Z"));
	}
}