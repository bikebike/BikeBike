Feature: Sign In
  Scenario: Sign in from the footer using email
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am on the landing page

    Then I should see a 'Sign In' link

    When I click the 'Sign In' link

    Then I should see 'Email address'
    And I enter my email
    And press confirm_email

    Then I should be on the do_confirm page
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should be on the settings page
    Then I should not see a 'My registration' link

  Scenario: Sign in from the settings page
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am on the settings page

    Then I should see 'Email address'
    And I enter my email
    And press confirm_email

    Then I should be on the do_confirm page
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should be on the settings page

  Scenario: Users can sign in in different sessions
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am on the settings page

    Then I should see 'Email address'
    And I enter my email
    And press confirm_email

    Then I should be on the do_confirm page
    And I should get a 'confirmation' email
    
    Then in a new session
    When I click on the 'Confirm' link in the email
    Then I should be on the confirmation page
    And I enter my email
    And click the 'Sign In' button
    
    Then I should be on the settings page

  Scenario: A registration link should be accessible for registered users
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am logged in
    And I am registered for the conference
    And I am on the settings page

    Then I should see a 'My registration' link

  Scenario: Conference hosts should see links to their conference
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am logged in
    And I am a conference host
    And I am on the settings page

    Then I should see 'Your Conferences'
    And I should see a 'Bike!Bike! 2015' link

  Scenario: New accounts created with Facebook are forced to add an email address
    Given there is an upcoming conference in 'Brooklyn NY'
    And I have a facebook account
    And my name is 'Mark Zuckerberg'
    But my facebook account has no email address

    When I log in with facebook
    Then I should be on the oauth_update page
    And I should see 'Before proceeding, you must provide us an email address'

    When I enter my email address
    And press save
    Then I should be on the home page
    And I should see 'Mark Zuckerberg'
    And I should see 'Sign out'