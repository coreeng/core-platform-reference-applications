Feature: Calling a counter service with persistent storage

  Scenario: Get counter endpoint with a name that doesn't exist with response returns OK
    Given a rest service
    When I call the get counter with the name 'arandomname'
    Then the response body is
    """json
{
    "name": "arandomname",
    "counter": 0
}
    """


  Scenario: Get counter endpoint with a random UUID with response returns OK
    Given a rest service
    And a random UUID
    When I call the get counter with the random UUID
    Then the response body field 'counter' is equal to '0'

  Scenario: Put counter endpoint with a random UUID with response returns OK
    Given a rest service
    And a random UUID
    When I call the put counter with the random UUID
    Then the response body field 'counter' is equal to '1'
    When I call the get counter with the random UUID
    Then the response body field 'counter' is equal to '1'