package integration_test

import (
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/cucumber/godog"
	"github.com/go-resty/resty/v2"
	log "github.com/sirupsen/logrus"
)

var baseUri = getBaseURI()
var ingressBaseUri = getIngressBaseUrl()
var request *resty.Request
var response resty.Response

func anApp() {
	httpClient := resty.New()
	request = httpClient.R()
}

func iCallTheEndpoint(path string) error {
	fullUrl := baseUri + path
	log.Debugf("Hitting GET endpoint %s", fullUrl)
	httpResponse, err := request.Get(fullUrl)

	if err != nil {
		return fmt.Errorf("call to %s was unsuccessful, error: %v", fullUrl, err)
	}

	response = *httpResponse
	return nil
}

func iCallTheIngressEndpointAndWaitForItToBeReady(path string) error {
	fullUrl := ingressBaseUri + path
	successful := false
	for i := 0; i < 8; i++ {
		log.Debugf("GET endpoint %s - retry number %d", fullUrl, i)
		httpResponse, err := request.Get(fullUrl)
		if err != nil {
			log.Debugf("call to %s was unsuccessful, error: %v. Sleeping for 10 seconds to wait for ingress to be available...", fullUrl, err)
			time.Sleep(10 * time.Second)
			continue
		}
		response = *httpResponse
		successful = true
		break
	}

	if !successful {
		return fmt.Errorf("call to %s was unsuccessful, error: %v", fullUrl, errors.New("unsuccessful call"))
	}

	return nil
}

func aResponseIsReturned(expectedStatusCode int) error {
	if response.StatusCode() == expectedStatusCode {
		return nil
	}
	return fmt.Errorf("expected status code %d, but got %d, error: %v", expectedStatusCode, response.StatusCode(), response.Error())
}

func InitializeScenario(ctx *godog.ScenarioContext) {
	ctx.Step(`^an app$`, anApp)
	ctx.Step(`^a (\d+) response is returned$`, aResponseIsReturned)
	ctx.Step(`^I call the "([^"]*)" endpoint via the service$`, iCallTheEndpoint)
	ctx.Step(`^I call the "([^"]*)" endpoint via the ingress$`, iCallTheIngressEndpointAndWaitForItToBeReady)
}

func getBaseURI() string {
	serviceEndpoint := os.Getenv("SERVICE_ENDPOINT")

	if serviceEndpoint == "" {
		return "http://service:8080"
	}
	return serviceEndpoint
}

func getIngressBaseUrl() string {
	return os.Getenv("INGRESS_ENDPOINT")
}
func TestFeatures(t *testing.T) {
	suite := godog.TestSuite{
		ScenarioInitializer: InitializeScenario,
		Options: &godog.Options{
			Format:      "pretty",
			Paths:       []string{"features"},
			TestingT:    t,
			Concurrency: 1,
		},
	}

	if suite.Run() != 0 {
		t.Fatal("non-zero status returned, failed to run feature tests")
	}
}
