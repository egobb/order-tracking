package com.egobb.orders.domain.model;

public enum Status {
	RECOGIDO_EN_ALMACEN, EN_REPARTO, INCIDENCIA_EN_ENTREGA, ENTREGADO;

	public boolean isInitial() {
		return this == RECOGIDO_EN_ALMACEN;
	}
	public boolean isFinal() {
		return this == ENTREGADO;
	}
}
