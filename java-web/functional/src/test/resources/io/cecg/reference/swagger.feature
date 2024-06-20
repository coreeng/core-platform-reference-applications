Feature: Swagger exists

  Scenario: Swagger endpoint returns ok
    Given a rest service
    When I call the swagger endpoint
    Then an ok response is returned