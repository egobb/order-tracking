package com.egobb.orders.contract.rest.controller.mapper;

import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventDTO;
import com.egobb.orders.contract.rest.controller.dto.TrackingEventsDTO;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.stream.Collectors;

@Component
public class TrackingEventMapper {
	public List<EnqueueTrackingEventCmd> toEnqueueCmdList(TrackingEventsDTO dto) {
		return dto.event.stream().map(this::toEnqueueCmd).collect(Collectors.toList());
	}

	private EnqueueTrackingEventCmd toEnqueueCmd(TrackingEventDTO d) {
		return new EnqueueTrackingEventCmd(d.orderId, d.status, d.eventTs);
	}
}