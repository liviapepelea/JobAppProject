Feature: Testing CSGOEmpire application

  Scenario: Test2
    Given I open CSGOEmpire website
    Then I input the value of bet amount as "10.5"
    Then I click a random number of buttons that modify the bet
    And I click "Max " button
    And I click "Clear " button
    And I quit the browser