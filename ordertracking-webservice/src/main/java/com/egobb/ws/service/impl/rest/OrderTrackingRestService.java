package com.egobb.ws.service.impl.rest;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;

@Path("/tracking")
public class OrderTrackingRestService {

  @GET
  @Produces(MediaType.TEXT_PLAIN)
  public String helloWorld() {
    return "Hello world ma brah";
  }

}

