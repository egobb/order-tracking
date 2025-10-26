package com.egobb.orders.contract.rest.controller;

import com.egobb.orders.application.handler.EnqueueTrackingEventCmdHandler;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventsDTO;
import com.egobb.orders.contract.rest.controller.mapper.TrackingEventMapper;
import jakarta.validation.Valid;
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

	private final TrackingEventMapper trackingEventMapper;

	private final EnqueueTrackingEventCmdHandler enqueueTrackingEventCmdHandler;

	@PostMapping(consumes = {MediaType.APPLICATION_JSON_VALUE, MediaType.APPLICATION_XML_VALUE})
	public ResponseEntity<Void> ingest(@Valid @RequestBody TrackingEventsDTO body) {
		this.trackingEventMapper.toEnqueueCmdList(body).forEach(this.enqueueTrackingEventCmdHandler::handle);
		return ResponseEntity.accepted().build();
	}

}
