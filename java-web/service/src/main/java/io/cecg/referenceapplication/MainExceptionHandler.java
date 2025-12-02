package io.cecg.referenceapplication;


import io.cecg.referenceapplication.api.dtos.ErrorResponseBody;
import io.cecg.referenceapplication.api.exceptions.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.ErrorResponse;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseBody;

@ControllerAdvice
@ResponseBody
public class MainExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(MainExceptionHandler.class);

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorResponseBody> handleGenericException(Exception e) {
        if (e instanceof ErrorResponse er) {
            return ResponseEntity.status(er.getStatusCode())
                    .body(new ErrorResponseBody(String.format("Something went wrong: %s", e.getMessage())));
        }
        return ResponseEntity.internalServerError()
                .body(new ErrorResponseBody(String.format("Something went wrong: %s", e.getMessage())));
    }

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ErrorResponseBody> handleApiException(ApiException e) {
        return new ResponseEntity<>(new ErrorResponseBody(e.getMessage()), e.getStatusCode());
    }
}
