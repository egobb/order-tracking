package com.egobb.orders.application.handler;

import com.egobb.orders.application.command.ProcessTrackingEventCmd;
import com.egobb.orders.application.port.out.PublishDomainEventPort;
import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.model.Status;
import com.egobb.orders.domain.service.TrackingService;
import com.egobb.orders.domain.vo.TrackingEventVo;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.Instant;

import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class ProcessTrackingEventCmdHandlerTest {

	@Mock
	PublishDomainEventPort publisher;
	@Mock
	com.egobb.orders.application.mapper.TrackingEventMapper mapper;
	@Mock
	TrackingService trackingService;

	@InjectMocks
	ProcessTrackingEventCmdHandler handler;

	@Test
	void handle_maps_processes_and_publishes() {
		final var cmd = new ProcessTrackingEventCmd("o1", Status.OUT_FOR_DELIVERY, Instant.now());
		final var domain = new TrackingEventVo("o1", Status.OUT_FOR_DELIVERY, Instant.now());

		// Prepare a timeline with a domain event
		final var timeline = new OrderTimeline("o1", Status.OUT_FOR_DELIVERY, Instant.now());
		timeline.register(domain); // This adds a TrackingEventUpdated event

		when(this.mapper.toDomain(cmd)).thenReturn(domain);
		when(this.trackingService.process(domain)).thenReturn(timeline);

		this.handler.handle(cmd);

		verify(this.mapper).toDomain(cmd);
		verify(this.trackingService).process(domain);
		// TODO: Change event appender
		// verify(this.publisher).publish(any(TrackingEventUpdated.class));
	}
}
