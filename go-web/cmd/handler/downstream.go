package handler

import (
	"fmt"
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"go.opentelemetry.io/contrib/instrumentation/net/http/otelhttp"
	"go.opentelemetry.io/otel/sdk/metric"
	"io"
	"net/http"
	"os"
)

type downstreamHandler struct {
	httpClient *http.Client
}

func newDownstreamHandler(provider *metric.MeterProvider) (*downstreamHandler, error) {
	httpClient, err := setupHTTPClientWith100MaxIdleConnsPerHost(provider)
	if err != nil {
		return nil, fmt.Errorf("failed to create http client: %w", err)
	}

	return &downstreamHandler{
		httpClient: httpClient,
	}, nil
}

func (h *downstreamHandler) handleDownstream(c *gin.Context) {
	url := downstreamEndpoint() + c.Param("path")

	r, err := h.httpClient.Get(url)
	if err != nil {
		log.Errorf("Failed with error %v", err)
		c.String(http.StatusBadGateway, err.Error())
		return
	}

	// The default HTTP client's Transport may not
	// reuse HTTP/1.x "keep-alive" TCP connections if the Body is
	// not read to completion and closed.
	defer r.Body.Close()

	b, err := io.ReadAll(r.Body)
	if err != nil {
		log.Errorf("Failed with error %v", err)
		c.String(http.StatusBadGateway, err.Error())
		return
	}

	c.Data(r.StatusCode, r.Header.Get("Content-Type"), b)
}

func setupHTTPClientWith100MaxIdleConnsPerHost(provider *metric.MeterProvider) (*http.Client, error) {
	t := &http.Transport{
		MaxIdleConnsPerHost: 100,
	}

	client := &http.Client{
		Transport: otelhttp.NewTransport(t, otelhttp.WithMeterProvider(provider)),
	}

	return client, nil
}

func downstreamEndpoint() string {
	endpoint := os.Getenv("DOWNSTREAM_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://wiremock"
	}

	return endpoint
}