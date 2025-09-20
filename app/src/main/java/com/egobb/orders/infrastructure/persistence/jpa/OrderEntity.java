package com.egobb.orders.infrastructure.persistence.jpa;

import com.egobb.orders.domain.model.Status;
import jakarta.persistence.*;
import java.time.Instant;

@Entity
@Table(name = "orders")
public class OrderEntity {
  @Id private String id;

  @Enumerated(EnumType.STRING)
  private Status lastStatus;

  private Instant deliveredAt;
  private Instant createdAt;
  private Instant updatedAt;

  public OrderEntity() {}

  public OrderEntity(String id, Status lastStatus, Instant deliveredAt) {
    this.id = id;
    this.lastStatus = lastStatus;
    this.deliveredAt = deliveredAt;
    this.createdAt = Instant.now();
    this.updatedAt = this.createdAt;
  }

  @PrePersist
  void prePersist() {
    if (this.createdAt == null) {
      this.createdAt = Instant.now();
      this.updatedAt = this.createdAt;
    }
  }

  @PreUpdate
  void touch() {
    this.updatedAt = Instant.now();
  }

  public String getId() {
    return this.id;
  }

  public void setId(String id) {
    this.id = id;
  }

  public Status getLastStatus() {
    return this.lastStatus;
  }

  public void setLastStatus(Status lastStatus) {
    this.lastStatus = lastStatus;
  }

  public Instant getDeliveredAt() {
    return this.deliveredAt;
  }

  public void setDeliveredAt(Instant deliveredAt) {
    this.deliveredAt = deliveredAt;
  }
}
