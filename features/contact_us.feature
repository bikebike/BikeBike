Feature: Contact Us
  Scenario: Contact the site administrator
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am on the landing page

    Then I should see a 'Contact Us' link

    When I click the 'Contact Us' link

    Then I should see 'What are you contacting us about?'
    Then I should see 'Email address'
    And I enter my email
    And select 'Something about the website'
    And enter a subject as 'My Contact Subject'
    And enter a message as 'My contact message'
    And press 'Send'

    Then I should be on the contact_sent page
    And I should see 'Thank you for contacting us'

    And the site administrator should get two 'My Contact Subject' emails
    And the site administrator should get a 'Details for' email

  Scenario: Contact the site administrator from the contact page
    Given there is an upcoming conference in 'Brooklyn NY'
    And I am logged in
    And I am on the contact page

    Then I should see 'What are you contacting us about?'
    And I should not see 'Email address'
    And select 'Something about the website'
    And enter a subject as 'My Contact Subject'
    And enter a message as 'My contact message'
    And press 'Send'

    Then I should be on the contact_sent page
    And I should see 'Thank you for contacting us'

    And the site administrator should get two 'My Contact Subject' emails
    And the site administrator should get a 'Details for' email
