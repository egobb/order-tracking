package com.egobb.orders.infrastructure.persistence.jpa;

import org.springframework.data.jpa.repository.JpaRepository;

public interface OrderJpaRepository extends JpaRepository<OrderEntity, String> {}
