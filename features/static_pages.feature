Feature: Static Pages

  Scenario: Read the about page
    Given There is an upcoming conference in 'Portland OR'
    And I am on the about page
    Then I should see 'What is Bike!Bike!?'

  Scenario: Read the policy page
    Given There is an upcoming conference in 'Regina, SK'
    And I am on the policy page
    Then I should see 'Safer Space Agreement'

  Scenario: See a 404 page
    Given There is an upcoming conference in 'Edmundston, NB'
    And I am on a 404 error page
    Then I should see 'The page you are looking for could not be found'

  Scenario: See a 500 page
    Given There is an upcoming conference in 'Souris, MB'
    And I am on a 500 error page
    Then I should see 'An error has occurred'

  Scenario: See a locale not available page
    Given There is an upcoming conference in 'Eldorado, MX'
    And I am on a locale not available error page
    Then I should see 'Klingon Translations Missing'
