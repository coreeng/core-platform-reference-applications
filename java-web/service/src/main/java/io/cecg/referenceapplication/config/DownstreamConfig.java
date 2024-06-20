package io.cecg.referenceapplication.config;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

@ConfigurationProperties(prefix = "downstream")
@Configuration
public class DownstreamConfig {
    private String url;
    private Integer port;
    private Long readTimeoutMs;
    private Long connectTimeoutMs;

    public String getFullUrl() {
        if (port == null)
            return url;
        else
            return String.format("%s:%d", url, port);
    }

    public String getFullUrlWithPath(String path) {
        return String.format("%s/%s", getFullUrl(), path);
    }

    public String getUrl() {
        return url;
    }

    public void setUrl(String url) {
        this.url = url;
    }

    public Integer getPort() {
        return port;
    }

    public void setPort(Integer port) {
        this.port = port;
    }

    public Long getReadTimeoutMs() {
        return readTimeoutMs;
    }

    public void setReadTimeoutMs(Long readTimeoutMs) {
        this.readTimeoutMs = readTimeoutMs;
    }

    public Long getConnectTimeoutMs() {
        return connectTimeoutMs;
    }

    public void setConnectTimeoutMs(Long connectTimeoutMs) {
        this.connectTimeoutMs = connectTimeoutMs;
    }
}