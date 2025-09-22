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

  @Override
  public String toString() {
    return this.name();
  }

  public static Status fromString(String value) {
    for (final Status status : Status.values()) {
      if (status.name().equalsIgnoreCase(value)) {
        return status;
      }
    }
    throw new IllegalArgumentException("Unknown Status: " + value);
  }
}
