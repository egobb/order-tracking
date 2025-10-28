package com.egobb.orders.domain.model;

import java.util.Map;
import java.util.Set;

public class StateMachine {
  private static final Map<Status, Set<Status>> allowed =
      Map.of(
          Status.PICKED_UP_AT_WAREHOUSE,
          Set.of(Status.OUT_FOR_DELIVERY, Status.DELIVERY_ISSUE),
          Status.OUT_FOR_DELIVERY,
          Set.of(Status.DELIVERY_ISSUE, Status.DELIVERED),
          Status.DELIVERY_ISSUE,
          Set.of(Status.OUT_FOR_DELIVERY, Status.DELIVERED),
          Status.DELIVERED,
          Set.of());

  public static boolean canTransition(Status from, Status to) {
    if (from == null) return to != null; // allow any first valid state
    if (from.isFinal()) return false;
    if (to == Status.PICKED_UP_AT_WAREHOUSE) return false; // cannot go back to initial
    return allowed.getOrDefault(from, Set.of()).contains(to);
  }
}
