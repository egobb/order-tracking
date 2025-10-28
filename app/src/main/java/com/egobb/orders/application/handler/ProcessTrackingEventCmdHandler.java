package com.egobb.orders.application.handler;

import com.egobb.orders.application.command.CommandHandler;
import com.egobb.orders.application.command.ProcessTrackingEventCmd;
import com.egobb.orders.application.mapper.TrackingEventMapper;
import com.egobb.orders.application.port.out.PublishDomainEventPort;
import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.service.TrackingService;
import io.vavr.control.Try;
import org.springframework.stereotype.Component;

@Component
public class ProcessTrackingEventCmdHandler implements CommandHandler<ProcessTrackingEventCmd> {

  private final PublishDomainEventPort publisher;
  private final TrackingEventMapper trackingEventMapper;
  private final TrackingService trackingService;

  public ProcessTrackingEventCmdHandler(
      PublishDomainEventPort publisher,
      TrackingEventMapper trackingEventMapper,
      TrackingService trackingService) {
    this.publisher = publisher;
    this.trackingEventMapper = trackingEventMapper;
    this.trackingService = trackingService;
  }

  @Override
  public Void handle(ProcessTrackingEventCmd cmd) {
    Try.of(() -> cmd)
        .map(this.trackingEventMapper::toDomain)
        .map(this.trackingService::process)
        .map(this::emitDomainEvents)
        .get();

    return null;
  }

  private OrderTimeline emitDomainEvents(final OrderTimeline orderTimeline) {
    for (final var event : orderTimeline.getDomainEvents()) {
      this.publisher.publish(event);
    }
    return orderTimeline;
  }
}
