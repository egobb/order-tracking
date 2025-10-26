package com.egobb.orders.application.port.in;

import com.egobb.orders.domain.event.TrackingEventReceived;

import java.util.List;

public interface ProcessTrackingUseCase {

	void ingestBatch(List<TrackingEventReceived> events);
}
