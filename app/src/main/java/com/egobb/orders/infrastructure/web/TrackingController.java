package com.egobb.orders.infrastructure.web;

import com.egobb.orders.application.usecase.IngestTrackingEventsUseCase;
import com.egobb.orders.domain.model.TrackingEvent;
import com.egobb.orders.infrastructure.web.dto.TrackingEventDTO;
import com.egobb.orders.infrastructure.web.dto.TrackingEventsDTO;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping(path = "/order/tracking")
public class TrackingController {
	private final IngestTrackingEventsUseCase useCase;
	public TrackingController(IngestTrackingEventsUseCase useCase) {
		this.useCase = useCase;
	}

	@PostMapping(consumes = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	public List<IngestTrackingEventsUseCase.Result> ingest(@Valid @RequestBody TrackingEventsDTO body) {
		final List<TrackingEvent> events = body.event.stream().map(this::toDomain).collect(Collectors.toList());
		return this.useCase.ingest(events);
	}

	private TrackingEvent toDomain(TrackingEventDTO d) {
		return new TrackingEvent(d.orderId, d.status, d.eventTs);
	}
}
