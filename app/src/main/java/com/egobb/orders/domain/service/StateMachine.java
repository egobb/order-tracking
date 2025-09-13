package com.egobb.orders.domain.service;

import com.egobb.orders.domain.model.Status;

import java.util.Map;
import java.util.Set;

public class StateMachine {
	private static final Map<Status, Set<Status>> allowed = Map.of(Status.RECOGIDO_EN_ALMACEN,
			Set.of(Status.EN_REPARTO, Status.INCIDENCIA_EN_ENTREGA), Status.EN_REPARTO,
			Set.of(Status.INCIDENCIA_EN_ENTREGA, Status.ENTREGADO), Status.INCIDENCIA_EN_ENTREGA,
			Set.of(Status.EN_REPARTO, Status.ENTREGADO), Status.ENTREGADO, Set.of());

	public boolean canTransition(Status from, Status to) {
		if (from == null)
			return to != null; // allow any first valid state
		if (from.isFinal())
			return false;
		if (to == Status.RECOGIDO_EN_ALMACEN)
			return false; // cannot go back to initial
		return allowed.getOrDefault(from, Set.of()).contains(to);
	}
}
