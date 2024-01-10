package com.egobb.ws.service.impl.rest;

import com.egobb.ws.domain.OrderStatusChangeWSDO;

import javax.ws.rs.Path;
import javax.ws.rs.core.Response;
import java.util.List;

@Path("/order/tracking")
public class OrderTrackingRestService {

    public Response processRequest(List<OrderStatusChangeWSDO> orderStatusChanges) {
        return Response.status(Response.Status.CREATED).build();
    }

}
