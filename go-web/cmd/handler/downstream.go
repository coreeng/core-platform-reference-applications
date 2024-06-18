package handler

import (
	"github.com/gin-gonic/gin"
	log "github.com/sirupsen/logrus"
	"io"
	"net/http"
	"os"
)

type downstreamHandler struct {
	httpClient *http.Client
}

func newDownstreamHandler() *downstreamHandler {
	return &downstreamHandler{
		httpClient: setupHTTPClient(),
	}
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

func setupHTTPClient() *http.Client {
	return &http.Client{
		Transport: &http.Transport{
			//https://pkg.go.dev/net/http#Transport
			// MaxIdleConnsPerHost, if non-zero, controls the maximum idle
			// (keep-alive) connections to keep per-host. If zero,
			// DefaultMaxIdleConnsPerHost(2) is used.
			MaxIdleConnsPerHost: 100,
		},
	}
}

func downstreamEndpoint() string {
	endpoint := os.Getenv("DOWNSTREAM_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://wiremock"
	}

	return endpoint
}