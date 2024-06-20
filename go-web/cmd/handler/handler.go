// Package handler is responsible for routes and handling requests
package handler

import (
	"fmt"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"go.opentelemetry.io/otel/sdk/metric"
	"net/http"

	"github.com/gin-gonic/gin"
)

// Router sets up routes
func Router(provider *metric.MeterProvider) (http.Handler, error) {
	router := gin.Default()

	setupHelloRoutes(router)
	if err := setupDownstreamRoutes(router, provider); err != nil {
		return nil, err
	}

	return router, nil
}

// InternalRouter configures the internal routes
func InternalRouter() http.Handler {
	router := gin.Default()
	// expose /metrics endpoint via internal server
	router.GET("/metrics", gin.WrapH(promhttp.Handler()))

	routerGroup1 := router.Group("/internal")
	routerGroup1.GET("/status", func(c *gin.Context) { c.Status(http.StatusOK) })
	return router
}

func setupHelloRoutes(r *gin.Engine) gin.IRoutes {
	return r.GET("/hello", handleHello)
}

func handleHello(c *gin.Context) {
	nameOrDefault := c.DefaultQuery("name", "world")
	c.String(http.StatusOK, "Hello %s", nameOrDefault)
}

func setupDownstreamRoutes(r *gin.Engine, provider *metric.MeterProvider) error {
	h, err := newDownstreamHandler(provider)
	if err != nil {
		return fmt.Errorf("failed to create downstream handler: %w", err)
	}

	r.GET("/downstream/*path", h.handleDownstream)
	return nil
}