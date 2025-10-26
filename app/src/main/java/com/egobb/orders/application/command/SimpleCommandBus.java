package com.egobb.orders.application.command;

import org.springframework.stereotype.Component;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SimpleCommandBus {
	private final Map<Class<?>, CommandHandler<?>> handlers = new ConcurrentHashMap<>();

	public <C extends Command> void register(Class<C> type, CommandHandler<C> handler) {
		this.handlers.put(type, handler);
	}

	@SuppressWarnings("unchecked")
	public <C extends Command> void dispatch(C command) {
		final var handler = (CommandHandler<C>) this.handlers.get(command.getClass());
		if (handler == null)
			throw new IllegalStateException("No handler for " + command.getClass());
		handler.handle(command);
	}
}