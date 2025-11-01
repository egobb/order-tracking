package com.egobb.orders.domain.model;

import com.egobb.orders.domain.event.DomainEvent;
import java.util.LinkedList;
import java.util.List;
import lombok.NonNull;

public class AggregationRoot {

  private final List<DomainEvent> domainEvents = new LinkedList<>();

  protected void addDomainEvent(@NonNull DomainEvent domainEvent) {
    this.domainEvents.add(domainEvent);
  }

  public List<DomainEvent> getDomainEvents() {
    return List.copyOf(this.domainEvents);
  }
}
