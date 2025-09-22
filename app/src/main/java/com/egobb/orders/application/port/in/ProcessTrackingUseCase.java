package com.egobb.orders.application.port.in;

import com.egobb.orders.domain.event.TrackingEvent;
import java.util.List;

public interface ProcessTrackingUseCase {

  void ingestBatch(List<TrackingEvent> events);
}
