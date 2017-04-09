Feature: Registration
  Scenario: Registration can really happen
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'
    
    And I should see the 'Policy' link
    But I should not see the 'Contact Info' link
    And I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    But I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I enter my name
    And fill in my location with 'Seattle'
    And click the 'Next' button
    Then I should see 'Do you need a place to stay?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    But I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    And I should see 'Your location was corrected from "Seattle" to "Seattle, Washington, United States"'

    When I check 'Indoor Location'
    And I check 'Yes'
    And I check 'Omnivore'
    And click the 'Register' button
    Then I should see 'Propose a Workshop'
    And I should get a 'Thank you for registering for Bike!Bike! 2025' email
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'

    And I should not see 'Hosting'
    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    And I should see the 'Workshops' link
    But I should not see the 'Donation' link

  Scenario: Housing providers can register
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'
    
    And I should see the 'Policy' link
    But I should not see the 'Contact Info' link
    And I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    But I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I enter my name
    And fill in my location with 'Brooklyn'
    And click the 'Next' button
    Then I should see 'Can you provide housing to attendees visiting the city?'
    And I should not see 'Do you need a place to stay?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Hosting'
    And see 'Workshops'
    But I should not see 'Your Visit'
    And I should not see 'Donation'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Hosting' link
    But I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    And I should see 'Your location was corrected from "Brooklyn" to "Brooklyn, New York, United States"'
    And I should see 'I can provide housing'
    But I should not see 'Your address and phone number will be shared with your guests and conference organizers'

    When I check 'I can provide housing'
    Then I should see 'Your address and phone number will be shared with your guests and conference organizers'

    When I enter my address
    And enter my phone
    And enter my bed space as '2'
    When I press the 'Next' button
    Then I should get a 'Thank you for registering for Bike!Bike! 2025' email
    And I should see 'Propose a Workshop'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Hosting' link
    And I should see the 'Workshops' link
    But I should not see the 'Donation' link

  Scenario: Housing providers who are not intending to register can register
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'
    
    And I should see the 'Policy' link
    But I should not see the 'Contact Info' link
    And I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    But I should not see 'Donation'
    And I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    But I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I enter my name
    And fill in my location with 'Brooklyn'
    And click the 'Next' button
    Then I should see 'Can you provide housing to attendees visiting the city?'
    And I should not see 'Do you need a place to stay?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Hosting'
    And see 'Workshops'
    But I should not see 'Your Visit'
    And I should not see 'Donation'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Hosting' link
    But I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    And I should see 'Your location was corrected from "Brooklyn" to "Brooklyn, New York, United States"'
    And I should see 'I can provide housing'
    But I should not see 'Your address and phone number will be shared with your guests and conference organizers'

    When I check 'I can provide housing'
    Then I should see 'Your address and phone number will be shared with your guests and conference organizers'

    When I enter my address
    And enter my phone
    And enter my bed space as '2'
    And check 'I will not be attending the conference'
    When I press the 'Next' button
    Then I should get a 'Thank you for registering for Bike!Bike! 2025' email
    And I should not see 'Propose a Workshop'
    But I should see 'Can you provide housing to attendees visiting the city?'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Hosting' link
    And I should not see the 'Workshops' link
    But I should not see the 'Donation' link

  Scenario: Users who live in neighbouring towns cannot be hosts by default
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And fill in my location with 'Newark NJ'
    And click the 'Next' button
    Then I should not see 'Can you provide housing to attendees visiting the city?'

  Scenario: Users who live in neighbouring towns can be housing providers if a radius is entered
    Given there is an upcoming conference in 'Brooklyn NY'
    And the conference accepts housing providers that live within 100km
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    
    When I click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And fill in my location with 'Newark'
    And click the 'Next' button
    Then I should see 'Can you provide housing to attendees visiting the city?'

  Scenario: Users can pay for registration
    Given there is an upcoming conference in 'Brooklyn NY'
    And the conference accepts paypal
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'
    
    And I should see the 'Policy' link
    But I should not see the 'Contact Info' link
    And I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    But I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I enter my name
    And fill in my location with 'Seattle'
    And click the 'Next' button
    Then I should see 'Do you need a place to stay?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    But I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    And I should see 'Your location was corrected from "Seattle" to "Seattle, Washington, United States"'

    When I check 'Indoor Location'
    And I check 'Yes'
    And I check 'Omnivore'
    And click the 'Register' button
    Then I should see 'Registration Fees'
    And I should get a 'Thank you for registering for Bike!Bike! 2025' email
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'

    And I should not see 'Hosting'
    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    And I should see the 'Donation' link
    But I should not see the 'Workshops' link

    And I should see '$25.00'
    And I should see '$50.00'
    And I should see '$100.00'
    And I should see 'Custom amount'
    And I should see 'Skip'

    When I click the '$50.00' button
    And finish with paypal
    Then I should see 'Please confirm your payment'
    And see 'You are about to confirm your payment of $50.00 for registration'

    When I click the 'Confirm' button
    Then I should see 'You have made a payment of $50.00'
    And see 'Thank you!'

    When I click the 'Skip' button
    Then I should see 'Propose a Workshop'

  Scenario: Users can fail to pay for registration
    Given there is an upcoming conference in 'Brooklyn NY'
    And the conference accepts paypal
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'
    
    And I should see the 'Policy' link
    But I should not see the 'Contact Info' link
    And I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    But I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I enter my name
    And fill in my location with 'Seattle'
    And click the 'Next' button
    Then I should see 'Do you need a place to stay?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    But I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    And I should see 'Your location was corrected from "Seattle" to "Seattle, Washington, United States"'

    When I check 'Indoor Location'
    And I check 'Yes'
    And I check 'Omnivore'
    And click the 'Register' button
    Then I should see 'Registration Fees'
    And I should get a 'Thank you for registering for Bike!Bike! 2025' email
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'

    And I should not see 'Hosting'
    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    And I should see the 'Donation' link
    But I should not see the 'Workshops' link

    And I should see '$25.00'
    And I should see '$50.00'
    And I should see '$100.00'
    And I should see 'Custom amount'
    And I should see 'Skip'

    When I click the '$50.00' button
    But I don't finish with paypal
    Then I should see 'Please confirm your payment'
    Then I should see 'Registration Fees'
    And see 'You are about to confirm your payment of $50.00 for registration'

    When I click the 'Confirm' button
    Then I should not see 'You have made a payment of $50.00'
    But I should see 'Your payment was not completed'

  Scenario: Users can decide not to pay for registration
    Given there is an upcoming conference in 'Brooklyn NY'
    And the conference accepts paypal
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Confirm Email'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Safer Space Agreement'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'
    
    And I should see the 'Policy' link
    But I should not see the 'Contact Info' link
    And I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I click on the 'I Agree' button
    Then I should see 'What is your name?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    But I should not see the 'Your Visit' link
    And I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    When I enter my name
    And fill in my location with 'Seattle'
    And click the 'Next' button
    Then I should see 'Do you need a place to stay?'
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'
    But I should not see 'Hosting'

    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    But I should not see the 'Donation' link
    And I should not see the 'Workshops' link

    And I should see 'Your location was corrected from "Seattle" to "Seattle, Washington, United States"'

    When I check 'Indoor Location'
    And I check 'Yes'
    And I check 'Omnivore'
    And click the 'Register' button
    Then I should see 'Registration Fees'
    And I should get a 'Thank you for registering for Bike!Bike! 2025' email
    And I should see 'Policy'
    And see 'Contact Info'
    And see 'Your Visit'
    And see 'Workshops'
    And see 'Donation'

    And I should not see 'Hosting'
    And I should see the 'Policy' link
    And I should see the 'Contact Info' link
    And I should see the 'Your Visit' link
    And I should see the 'Donation' link
    But I should not see the 'Workshops' link

    And I should see '$25.00'
    And I should see '$50.00'
    And I should see '$100.00'
    And I should see 'Custom amount'
    And I should see 'Skip'

    When I click the 'Skip' button
    Then I should see 'Propose a Workshop'
