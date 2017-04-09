Feature: Conferences
  Scenario: Multiple conferences can be displayed on the list page
    Given there is an upcoming conference in 'Brooklyn NY'
    And an upcoming regional conference in 'Yellowknife'
    And a past conference in 'New Orleans'
    And I am on the conferences page

    Then I should see 'Brooklyn'
    And see 'Yellowknife'
    And see 'New Orleans'

  Scenario: Only public conferences are displayed on the conference list page
    Given there is an upcoming conference in 'Brooklyn NY'
    And an upcoming regional conference in 'Yellowknife'
    And a past conference in 'New Orleans'
    But it is not public
    And I am on the conferences page

    Then I should see 'Brooklyn'
    And see 'Yellowknife'
    But I should not see 'New Orleans'

  Scenario: Non-public conferences can be seen by hosts
    Given there is an upcoming regional conference in 'Yellowknife'
    And a past conference in 'New Orleans'
    And an upcoming conference in 'Brooklyn NY'
    But the conference is not public
    And the conference is not featured
    And I am logged in
    And I am a conference host
    And I am on the conferences page

    Then I should see 'Brooklyn'
    And see 'Yellowknife'
    And see 'New Orleans'

  Scenario: Site administrators should be able to create and edit conferences
    Given there is an upcoming regional conference in 'Yellowknife'
    And a past conference in 'New Orleans'
    And an upcoming conference in 'Brooklyn NY'
    And I am logged in
    And I am an admin

    But the conference is not public
    And the conference is not featured
    And I am on the conferences page

    Then I should see 'Brooklyn'
    And see 'Yellowknife'
    And see 'New Orleans'
    And see a 'Create' link
    And see an 'Edit' link

  Scenario: Conference info page shows conference details
    Given there is an upcoming regional conference in 'Yellowknife'
    And a past conference in 'New Orleans'
    And an upcoming conference in 'Brooklyn NY'
    And I am on the conference page

    Then I should see 'Brooklyn'
    But I should not see 'Yellowknife'
    And not see 'New Orleans'
    And not see 'More info'
    And not see a 'Register' link
    And I should not see an 'Administrate' link
    And I should not see an 'Edit' link

  Scenario: Conference info page shows a register link
    Given there is an upcoming regional conference in 'Yellowknife'
    And a past conference in 'New Orleans'
    And an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the conference page

    Then I should see 'Brooklyn'
    But I should not see 'Yellowknife'
    And not see 'New Orleans'
    And not see 'More info'
    But I should see a 'Register' link
    And I should not see an 'Administrate' link
    And I should not see an 'Edit' link

  Scenario: Conferences that are not public cannot be viewed
    Given there is an upcoming conference in 'Brooklyn NY'
    But it is not public
    And I am logged in
    And I am on the conference page

    Then I should not see 'Brooklyn'
    But I should see 'Access Denied'
    And I should not see an 'Edit' link

  Scenario: Conferences that are not public can be viewed by hosts
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am logged in
    And I am a conference host
    And I am on the conference page

    Then I should see 'Brooklyn'
    But I should not see 'Access Denied'
    And I see an 'Administrate' link
    And I should not see an 'Edit' link

  Scenario: Site administrators should be able to view and edit conferences
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am logged in
    And I am an admin
    And I am on the conference page

    Then I should see 'Brooklyn'
    But I should not see 'Access Denied'
    And I see an 'Administrate' link
    And I should not see an 'Edit' link
