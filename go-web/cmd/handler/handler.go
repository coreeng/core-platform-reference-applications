// Package handler is responsible for routes and handling requests
package handler

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// Router sets up routes
func Router() http.Handler {
	router := gin.Default()

	setupHelloRoutes(router)
	setupDownstreamRoutes(router)
	return router
}

// InternalRouter configures the internal routes
func InternalRouter() http.Handler {
	router := gin.Default()
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

func setupDownstreamRoutes(r *gin.Engine) gin.IRoutes {
	h := newDownstreamHandler()
	return r.GET("/downstream/*path", h.handleDownstream)
}