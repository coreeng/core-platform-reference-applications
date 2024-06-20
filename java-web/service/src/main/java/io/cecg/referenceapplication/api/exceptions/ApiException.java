package io.cecg.referenceapplication.api.exceptions;

import org.springframework.http.HttpStatus;

public abstract class ApiException extends Exception {
    private final HttpStatus statusCode;

    public ApiException(HttpStatus statusCode) {
        super();
        this.statusCode = statusCode;
    }

    public ApiException(String message, HttpStatus statusCode) {
        super(message);
        this.statusCode = statusCode;
    }

    public ApiException(Exception exception, HttpStatus statusCode) {
        super(exception);
        this.statusCode = statusCode;
    }

    public HttpStatus getStatusCode() {
        return statusCode;
    }
}