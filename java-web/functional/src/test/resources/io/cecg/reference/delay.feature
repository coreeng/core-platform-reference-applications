Feature: Calling a downstream service with response delay set-up

  Scenario: Downstream endpoint with response returns OK
    Given a rest service
    When I call the downstream endpoint with 2 seconds of response delay
    Then an ok response is returned
    And the response body is
    """json
{
    "status": "OK"
}
    """

  Scenario: Downstream endpoint with response delay times out
    Given a rest service
    When I call the downstream endpoint with 6 seconds of response delay
    Then an '504' response is returned
    And the response body is
    """json
{
    "message": "Timeout calling a downstream endpoint"
}
    """