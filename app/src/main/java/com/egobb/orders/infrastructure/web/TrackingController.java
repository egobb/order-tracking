package com.egobb.orders.infrastructure.web;

import com.egobb.orders.application.port.in.ProcessTrackingUseCase;
import com.egobb.orders.domain.event.TrackingEvent;
import com.egobb.orders.infrastructure.web.dto.TrackingEventDTO;
import com.egobb.orders.infrastructure.web.dto.TrackingEventsDTO;
import jakarta.validation.Valid;
import java.util.List;
import java.util.stream.Collectors;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping(path = "/order/tracking")
@RequiredArgsConstructor
public class TrackingController {

  private final ProcessTrackingUseCase useCase;

  @PostMapping(consumes = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
  public ResponseEntity<Void> ingest(@Valid @RequestBody TrackingEventsDTO body) {
    final List<TrackingEvent> events =
        body.event.stream().map(this::toDomain).collect(Collectors.toList());
    this.useCase.ingestBatch(events);
    return ResponseEntity.accepted().build();
  }

  private TrackingEvent toDomain(TrackingEventDTO d) {
    return new TrackingEvent(d.orderId, d.status, d.eventTs);
  }
}
