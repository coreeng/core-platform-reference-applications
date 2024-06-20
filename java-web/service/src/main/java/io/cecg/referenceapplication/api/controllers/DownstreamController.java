package io.cecg.referenceapplication.api.controllers;

import io.cecg.referenceapplication.api.dtos.StatusResponse;
import io.cecg.referenceapplication.api.exceptions.ApiException;
import io.cecg.referenceapplication.domain.http.DownstreamConnector;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;

@RestController(value = "downstream")
@ResponseBody
public class DownstreamController {
    private static final StatusResponse OK_RESPONSE = new StatusResponse("OK");
    private final DownstreamConnector downstreamConnector;

    public DownstreamController(DownstreamConnector downstreamConnector) {
        this.downstreamConnector = downstreamConnector;
    }

    @GetMapping("/delay/{delay}")
    public StatusResponse getDelay(@PathVariable(value = "delay") Integer delay) throws ApiException {
        downstreamConnector.getDelay(delay);
        return OK_RESPONSE;
    }

    @GetMapping("/status/{status}")
    public StatusResponse getStatus(@PathVariable(value = "status") Integer status) throws ApiException {
        downstreamConnector.getStatus(status);
        return OK_RESPONSE;
    }

}