package io.cecg.referenceapplication.domain.http;

import io.cecg.referenceapplication.api.exceptions.ApiException;
import io.cecg.referenceapplication.api.exceptions.DownstreamTimeoutException;
import io.cecg.referenceapplication.api.exceptions.DownstremException;
import io.cecg.referenceapplication.config.DownstreamConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpMethod;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.*;

import java.util.Optional;

@Component
public class DownstreamConnector {
    private static final Logger log = LoggerFactory.getLogger(DownstreamConnector.class);

    private final RestTemplate restTemplate;
    private final DownstreamConfig downstreamConfig;
    private final String DELAY_PATH = "/delay/%d";
    private final String STATUS_PATH = "/status/%d";


    @Autowired
    public DownstreamConnector(DownstreamConfig downstreamConfig) {
        this.restTemplate = new RestTemplate();
        this.downstreamConfig = downstreamConfig;
        SimpleClientHttpRequestFactory httpRequestFactory = (SimpleClientHttpRequestFactory) restTemplate
                .getRequestFactory();
        httpRequestFactory.setReadTimeout(Optional.ofNullable(downstreamConfig.getReadTimeoutMs()).orElse(0L).intValue());
        httpRequestFactory.setConnectTimeout(Optional.ofNullable(downstreamConfig.getConnectTimeoutMs()).orElse(0L).intValue());
    }


    private String executeRequest(String path) throws ApiException { // throw exception
        try {
            ResponseEntity<String> response = restTemplate
                    .exchange(downstreamConfig.getFullUrlWithPath(path),
                            HttpMethod.GET, null, String.class);
            if (response.getStatusCodeValue() >= 400) {
                throw new DownstremException(String.format("Client failed with the status code \"%d\"", response.getStatusCodeValue()));
            }
            return response.getBody();

        } catch (HttpClientErrorException| HttpServerErrorException e) {
            log.error("Client error exception: {}", e.getMessage());
            throw new DownstremException(String.format("Client failed with status '%s'", e.getStatusCode().toString()));
        }
        catch (UnknownHttpStatusCodeException e) {
            log.error("Client error exception: {}", e.getMessage());
            throw new DownstremException("Client failed because of unknown status code requested");
        } catch(ResourceAccessException e) {
            log.error("Timeout Exception");
            throw new DownstreamTimeoutException("Timeout calling a downstream endpoint");
        }
        catch (Exception e) {
            log.error("Something went wrong", e);
            throw new DownstremException(e);
        }
    }

    public void getDelay(long delay) throws ApiException {
        executeRequest(String.format(DELAY_PATH, delay));
    }

    public void getStatus(long delay) throws ApiException {
        executeRequest(String.format(STATUS_PATH, delay));
    }
}