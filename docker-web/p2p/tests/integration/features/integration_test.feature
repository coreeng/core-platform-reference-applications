Feature: Integration Test
  Test app deployment in integration test environment is ready

  Scenario: Health check returns ok via service
    Given an app
    When I call the "/healthz" endpoint via the service
    Then a 200 response is returned

  Scenario: Health check returns ok via ingress
    Given an app
    When I call the "/healthz" endpoint via the ingress
    Then a 200 response is returned
