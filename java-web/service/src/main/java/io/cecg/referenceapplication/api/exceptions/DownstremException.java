package io.cecg.referenceapplication.api.exceptions;

import org.springframework.http.HttpStatus;

public class DownstremException extends ApiException{

    private static final HttpStatus status = HttpStatus.INTERNAL_SERVER_ERROR;
    public DownstremException(String message) {
        super(message, status);
    }

    public DownstremException(Exception e) {
        super(e, status);
    }
}