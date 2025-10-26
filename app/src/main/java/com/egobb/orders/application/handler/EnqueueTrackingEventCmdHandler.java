package com.egobb.orders.application.handler;

import com.egobb.orders.application.command.CommandHandler;
import com.egobb.orders.application.command.EnqueueTrackingEventCmd;
import com.egobb.orders.application.command.SimpleCommandBus;
import com.egobb.orders.application.mapper.TrackingEventMapper;
import com.egobb.orders.application.port.out.PublishDomainEventPort;
import com.egobb.orders.domain.event.TrackingEventReceived;
import io.vavr.control.Try;
import jakarta.annotation.PostConstruct;
import org.springframework.stereotype.Component;

@Component
public class EnqueueTrackingEventCmdHandler implements CommandHandler<EnqueueTrackingEventCmd> {

	private final SimpleCommandBus bus;
	private final PublishDomainEventPort publisher;
	private final TrackingEventMapper trackingEventMapper;

	public EnqueueTrackingEventCmdHandler(SimpleCommandBus bus, PublishDomainEventPort publisher,
			TrackingEventMapper trackingEventMapper) {
		this.bus = bus;
		this.publisher = publisher;
		this.trackingEventMapper = trackingEventMapper;
	}

	@PostConstruct
	void register() {
		this.bus.register(EnqueueTrackingEventCmd.class, this);
	}

	@Override
	public Void handle(EnqueueTrackingEventCmd cmd) {
		Try.of(() -> cmd).map(this.trackingEventMapper::toDomain).map(this::emitDomainEvents).get();
		return null;
	}

	private TrackingEventReceived emitDomainEvents(final TrackingEventReceived trackingEventReceived) {
		this.publisher.publish(trackingEventReceived);
		return trackingEventReceived;
	}
}
