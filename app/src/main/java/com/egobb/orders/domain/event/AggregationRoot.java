package com.egobb.orders.domain.event;

import lombok.NonNull;

import java.util.LinkedList;
import java.util.List;

public class AggregationRoot {

	private final List<DomainEvent> domainEvents = new LinkedList<>();

	protected void addDomainEvent(@NonNull DomainEvent domainEvent) {
		this.domainEvents.add(domainEvent);
	}

	public List<DomainEvent> getDomainEvents() {
		return List.copyOf(this.domainEvents);
	}

}
