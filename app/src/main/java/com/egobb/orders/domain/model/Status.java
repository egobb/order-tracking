package com.egobb.orders.domain.model;

public enum Status {
  PICKED_UP_AT_WAREHOUSE,
  OUT_FOR_DELIVERY,
  DELIVERY_ISSUE,
  DELIVERED;

  public boolean isInitial() {
    return this == PICKED_UP_AT_WAREHOUSE;
  }

  public boolean isFinal() {
    return this == DELIVERED;
  }
}
