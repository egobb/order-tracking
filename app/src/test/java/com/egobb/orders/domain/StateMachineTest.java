package com.egobb.orders.domain;

import com.egobb.orders.domain.model.StateMachine;
import com.egobb.orders.domain.model.Status;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;

public class StateMachineTest {
	StateMachine sm = new StateMachine();

	@Test
	void delivered_is_absorbing() {
		assertFalse(StateMachine.canTransition(Status.DELIVERED, Status.OUT_FOR_DELIVERY));
	}

	@Test
	void cannot_go_back_to_initial() {
		assertFalse(StateMachine.canTransition(Status.OUT_FOR_DELIVERY, Status.PICKED_UP_AT_WAREHOUSE));
	}
}
