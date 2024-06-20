Feature: Calling a status endpoint

  Scenario Outline: Status returns ok
    Given a rest service
    When I call the status endpoint with <status> status code
    Then an ok response is returned
    And the response body is
    """json
{
    "status": "OK"
}
    """
    Examples:
      | status |
      | 200    |
      | 201    |
      | 202    |
      | 203    |
      | 204    |
      | 205    |
      | 206    |
      | 207    |
      | 208    |
      | 226    |

  Scenario Outline: Status returns server internal error
    Given a rest service
    When I call the status endpoint with <status> status code
    Then an '500' response is returned
    Examples:
      | status |
      | 400    |
      | 401    |
      | 402    |
      | 403    |
      | 404    |
      | 405    |
      | 406    |
      | 407    |
      | 408    |
      | 409    |
      | 410    |
      | 411    |
      | 412    |
      | 413    |
      | 414    |
      | 415    |
      | 416    |
      | 417    |
      | 418    |
      | 421    |
      | 422    |
      | 423    |
      | 424    |
      | 425    |
      | 426    |
      | 428    |
      | 429    |
      | 431    |
      | 451    |
      | 500    |
      | 501    |
      | 502    |
      | 503    |
      | 504    |
      | 505    |
      | 506    |
      | 507    |
      | 508    |
      | 510    |
      | 511    |

  Scenario: Calling status with a non existing code
    Given a rest service
    When I call the status endpoint with 490 status code
    Then an '500' response is returned
    And the response body is
    """json
{
    "message": "Client failed because of unknown status code requested"
}
    """