package io.cecg.referenceapplication.api.exceptions;

import org.springframework.http.HttpStatus;

public class DownstreamTimeoutException extends ApiException{

    private static final HttpStatus status = HttpStatus.GATEWAY_TIMEOUT;
    public DownstreamTimeoutException(String message) {
        super(message, status);
    }

    public DownstreamTimeoutException(Exception e) {
        super(e, status);
    }
}