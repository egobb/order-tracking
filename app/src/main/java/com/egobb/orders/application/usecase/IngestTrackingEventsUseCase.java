package com.egobb.orders.application.usecase;

import com.egobb.orders.domain.model.OrderTimeline;
import com.egobb.orders.domain.model.TrackingEvent;
import com.egobb.orders.domain.ports.EventAppender;
import com.egobb.orders.domain.ports.OrderTimelineRepository;
import com.egobb.orders.domain.service.StateMachine;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class IngestTrackingEventsUseCase {
  private final OrderTimelineRepository repository;
  private final EventAppender appender;
  private final StateMachine sm;

  public IngestTrackingEventsUseCase(
      OrderTimelineRepository repository, EventAppender appender, StateMachine sm) {
    this.repository = repository;
    this.appender = appender;
    this.sm = sm;
  }

  public List<Result> ingest(List<TrackingEvent> events) {
    final List<Result> out = new ArrayList<>();
    for (final TrackingEvent e : events) out.add(this.processOne(e));
    return out;
  }

  private Result processOne(TrackingEvent e) {
    final Optional<OrderTimeline> maybe = this.repository.findById(e.orderId());
    final OrderTimeline tl = maybe.orElse(new OrderTimeline(e.orderId(), null, null));
    if (!this.sm.canTransition(tl.lastStatus(), e.status())) {
      return Result.rejected(
          e.orderId(), "Transition not allowed from " + tl.lastStatus() + " to " + e.status());
    }
    tl.apply(e.status(), e.eventTs());
    this.repository.save(tl);
    this.appender.append(e);
    return Result.accepted(e.orderId());
  }

  public record Result(String orderId, boolean accepted, String reason) {
    public static Result accepted(String orderId) {
      return new Result(orderId, true, null);
    }

    public static Result rejected(String orderId, String reason) {
      return new Result(orderId, false, reason);
    }
  }
}
