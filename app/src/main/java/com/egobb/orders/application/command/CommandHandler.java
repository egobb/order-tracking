package com.egobb.orders.application.command;

public interface CommandHandler<C extends Command> {
	Void handle(C command);
}
