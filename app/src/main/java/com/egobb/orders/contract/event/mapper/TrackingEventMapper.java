package com.egobb.orders.contract.event.mapper;

import com.egobb.orders.domain.event.TrackingEventReceived;
import com.egobb.orders.domain.model.Status;
import com.egobb.orders.domain.vo.TrackingEventVo;
import java.time.Instant;

public class TrackingEventMapper {

  private TrackingEventMapper() {}

  public record TrackingEventMsg(
      String orderId, String status, Instant eventTs, String schemaVersion) {}

  public static TrackingEventMsg toMsg(TrackingEventReceived ev) {
    return new TrackingEventMsg(ev.orderId(), ev.status().toString(), ev.eventTs(), "v1");
  }

  public static TrackingEventVo toDomain(TrackingEventMsg msg) {
    return new TrackingEventVo(msg.orderId(), Status.fromString(msg.status()), msg.eventTs());
  }
}
