package com.egobb.orders.domain;

import static org.junit.jupiter.api.Assertions.assertFalse;

import com.egobb.orders.domain.model.Status;
import com.egobb.orders.domain.service.StateMachine;
import org.junit.jupiter.api.Test;

public class StateMachineTest {
  StateMachine sm = new StateMachine();

  @Test
  void delivered_is_absorbing() {
    assertFalse(this.sm.canTransition(Status.DELIVERED, Status.OUT_FOR_DELIVERY));
  }

  @Test
  void cannot_go_back_to_initial() {
    assertFalse(this.sm.canTransition(Status.OUT_FOR_DELIVERY, Status.PICKED_UP_AT_WAREHOUSE));
  }
}
