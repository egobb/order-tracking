package com.egobb.orders.domain;

import com.egobb.orders.domain.model.Status;
import com.egobb.orders.domain.service.StateMachine;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;

public class StateMachineTest {
	StateMachine sm = new StateMachine();

	@Test
	void delivered_is_absorbing() {
		assertFalse(this.sm.canTransition(Status.ENTREGADO, Status.EN_REPARTO));
	}

	@Test
	void cannot_go_back_to_initial() {
		assertFalse(this.sm.canTransition(Status.EN_REPARTO, Status.RECOGIDO_EN_ALMACEN));
	}
}
