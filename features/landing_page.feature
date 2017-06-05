Feature: Landing Page
  In order to learn about Bike!Bike!
  As a visitor

  Scenario: A more info link is displayed before registration is open
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am on the landing page

    Then I should see a 'Details' link

  Scenario: A registration link is displayed when registration is open
    Given there is an upcoming conference in 'Brooklyn NY'
    And Registration is open
    And I am on the landing page
    
    Then I should see a 'Details' link
    And see a 'Register' link
    And see 'Brooklyn'

  Scenario: Multiple conferences can be displayed on the front page
    Given there is an upcoming conference in 'Brooklyn NY'
    And There is an upcoming regional conference in 'Yellowknife'
    And I am on the landing page

    Then I should see 'Brooklyn'
    And see 'Yellowknife'
    And see 'Northwest Territories'

  Scenario: Conferneces don't require a poster or date
    Given there is an upcoming conference in 'Drumheller AB'
    But the conference has no poster
    And it has no date
    And I am on the landing page
    
    Then I should see 'Drumheller'
    And see 'Alberta'

  Scenario: Only public and featured conferences are displayed on the front page
    Given there is an upcoming conference in 'Brooklyn NY'
    And there is an upcoming regional conference in 'Portland OR'
    But it is not featured
    And there is an upcoming regional conference in 'Prince Rupert BC'
    But it is not public
    And I am on the landing page
    
    Then I should see 'Brooklyn'
    But I should not see 'Portland'
    And I should not see 'Prince Rupert'
