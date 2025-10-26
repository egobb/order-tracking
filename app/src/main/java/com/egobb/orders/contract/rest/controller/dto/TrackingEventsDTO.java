package com.egobb.orders.contract.rest.controller.dto;

import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlElementWrapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlRootElement;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotEmpty;

import java.util.List;

@JacksonXmlRootElement(localName = "events")
public class TrackingEventsDTO {
	@NotEmpty
	@Valid
	@JacksonXmlElementWrapper(useWrapping = false)
	public List<TrackingEventDTO> event;
}
