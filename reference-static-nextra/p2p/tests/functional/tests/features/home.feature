Feature: Page Title

  Scenario: Verify page title displays correctly
    Given User navigates to the homepage
    Then It should show the title "Hello World"

  Scenario: Verify page title through ingress
    Given User navigates to the ingress homepage
    Then It should show the title "Hello World"
