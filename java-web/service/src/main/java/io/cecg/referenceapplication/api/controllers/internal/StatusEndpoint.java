package io.cecg.referenceapplication.api.controllers.internal;

import io.cecg.referenceapplication.api.dtos.StatusResponse;
import org.springframework.boot.actuate.endpoint.annotation.Endpoint;
import org.springframework.boot.actuate.endpoint.annotation.ReadOperation;
import org.springframework.stereotype.Component;
import org.springframework.util.MimeTypeUtils;

@Component
@Endpoint(id = "status")
public class StatusEndpoint {

    @ReadOperation(produces = MimeTypeUtils.APPLICATION_JSON_VALUE)
    public StatusResponse status() {
        return new StatusResponse("OK");
    }
}