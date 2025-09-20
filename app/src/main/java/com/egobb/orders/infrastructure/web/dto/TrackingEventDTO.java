package com.egobb.orders.infrastructure.web.dto;

import com.egobb.orders.domain.model.Status;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;

@JacksonXmlRootElement(localName = "event")
public class TrackingEventDTO {
  @NotBlank public String orderId;
  @NotNull public Status status;
  @NotNull public Instant eventTs;
}
