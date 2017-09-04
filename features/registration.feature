Feature: Registration
  Scenario: Attendees can register as expected
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And there is an organization named 'Bike Works' in Seattle
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Check your spam box'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Policy'
    And I should see 'The Agreement'
    And see 'Ensuring that all attendees feel welcome, safe, and respected at all times is especially important to us all'

    When I check commitment
    And check respect
    And check empowerment
    And check accessible
    And check peaceful
    And check spaces
    And check hearing
    And check intent
    And check open minds
    And check learning
    And click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And enter my pronoun as 'They'
    And click the 'Next' button
    Then I should see 'Which languages do you speak?'

    When I click the 'Next' button
    Then I should see 'Do you participate in a community bicycle project?'

    When I click the 'Yes' button
    Then I should see 'In which city or town is your organization based?'

    When I fill in my location with 'Seattle'
    And click the 'Next' button
    Then I should see 'Did you mean Seattle, Washington, United States?'

    When I click the 'Yes' button
    Then I should see 'Which organization are you a member of?'
    And I should see 'Bike Works'
    And see 'None of the above'

    When I click on the 'Bike Works' button
    Then I should see 'Arrival Date'

    When I click on the '25' button
    Then I should see 'Departure Date'

    When I click on the '11' button
    Then I should see 'Housing'
    And see 'Do you need a place to stay'

    When I click on the 'Yes, I would like to place to stay' button
    Then I should see 'Housing Companion'

    When I click on the 'Yes' button
    Then I should see 'Companion Email'

    When I fill in the email with 'my-friend@bikebike.org'
    And click the 'Next' button
    Then I should see 'What are your eating habits?'

    When I click on 'I eat meat and dairy'
    Then I should see 'Would you like to borrow a bike?'

    When I click on the 'Yes' button
    Then I should see 'Do you plan to attend the group ride?'

    When I click on the 'Yes' button
    Then I should see 'Other considerations'

    When I fill in other with 'Thanks!'
    And click the 'Next' button
    Then I should see 'Registration Fee Method'

    When I click on 'pay on arrival'
    Then I should see 'Registration Fee Amount'

    When I click on the '$25.00' button
    Then I should get a 'Thank you for registering' email
    And I should see 'Your registration is complete'
    And I should see 'Seattle'
    And see 'They'
    And see 'Bike Works'
    And see 'Yes, I would like to place to stay'
    And see 'I eat meat and dairy'
    And see 'Thanks!'
    And see 'In person'
    And see '$25.00 USD'

    When I click on 'Cancel my registration'
    Then I should see 'You have cancelled your registration'
    And I should see 'Re-open my registration'
    But I should not see 'Seattle'
    And should not see 'Bike Works'
    And should not see 'Yes, I would like to place to stay'
    And should not see 'I eat meat and dairy'
    And should not see 'Thanks!'
    And should not see 'In person'
    And should not see '$25.00 USD'
    
    When I click on 'Re-open my registration'
    Then I should see 'Your registration is complete'
    And I should see 'Seattle'
    And see 'Bike Works'
    And see 'Yes, I would like to place to stay'
    And see 'I eat meat and dairy'
    And see 'Thanks!'
    And see 'In person'
    And see '$25.00 USD'

  Scenario: Attendees can add a new organization
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Check your spam box'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Policy'
    And I should see 'The Agreement'
    And see 'Ensuring that all attendees feel welcome, safe, and respected at all times is especially important to us all'

    When I check commitment
    And check respect
    And check empowerment
    And check accessible
    And check peaceful
    And check spaces
    And check hearing
    And check intent
    And check open minds
    And check learning
    And click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And click the 'Next' button
    Then I should see 'Which languages do you speak?'

    When I click the 'Next' button
    Then I should see 'Do you participate in a community bicycle project?'

    When I click the 'Yes' button
    Then I should see 'In which city or town is your organization based?'

    When I fill in my location with 'Moncton'
    And click the 'Next' button
    Then I should see 'Did you mean Moncton, New Brunswick, Canada?'

    When I click the 'Yes' button
    Then I should see 'What is the name of your organization?'

    When I fill in the name with 'Coopérative La Bikery Cooperative'
    And click the 'Next' button
    Then I should see 'Organization Address'

    When I fill in the address with '120 Assomption Blvd'
    And click the 'Next' button
    Then I should see 'Organization Email'

    When I fill in the email with 'labikery@bikebike.org'
    And click the 'Next' button
    Then I should see 'Organization Mailing Address'

    When I fill in the mailing address with '120 Assomption Blvd'
    And click the 'Next' button
    And click on the '25' button
    And click on the '11' button
    And click on the 'I don't need a place to stay' button
    And click on 'I am vegan'
    And click on the 'No' button
    And click on the 'No' button
    And click the 'Next' button
    And click on 'pay now with PayPal'
    And click on the '$25.00' button
    And click the 'Confirm' button
    Then I should get a 'Thank you for registering' email
    And I should see 'Moncton'
    And I should see 'Coopérative La Bikery Cooperative'
    And I should see 'I don't need a place to stay'
    And I should see 'I am vegan'

  Scenario: Attendees can register without being a member of an organization
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Check your spam box'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Policy'
    And I should see 'The Agreement'
    And see 'Ensuring that all attendees feel welcome, safe, and respected at all times is especially important to us all'

    When I check commitment
    And check respect
    And check empowerment
    And check accessible
    And check peaceful
    And check spaces
    And check hearing
    And check intent
    And check open minds
    And check learning
    And click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And click the 'Next' button
    Then I should see 'Which languages do you speak?'

    When I click the 'Next' button
    Then I should see 'Do you participate in a community bicycle project?'

    When I click the 'No' button
    Then I should see 'In which city or town are you based?'

    When I fill in my location with 'Ecum Secum'
    And click the 'Next' button
    Then I should see 'Did you mean Ecum Secum, Nova Scotia, Canada?'

    When I click the 'Yes' button
    Then I should see 'Why are you interested in attending Bike!Bike!?'

    When I fill in my interest with 'Because Reasons'
    And click the 'Next' button
    And click on the '25' button
    And click on the '11' button
    And click on the 'I would like a place to tent' button
    And click on 'I am vegetarian'
    And click on the 'Yes' button
    And click on the 'No' button
    And click the 'Next' button
    And click on the 'Not now' button
    Then I should get a 'Thank you for registering' email
    And I should see 'Ecum Secum'
    And I should see 'Because Reasons'
    And I should see 'I am vegetarian'

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
    Then I should see 'Check your spam box'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Policy'
    And I should see 'The Agreement'
    And see 'Ensuring that all attendees feel welcome, safe, and respected at all times is especially important to us all'

    When I check commitment
    And check respect
    And check empowerment
    And check accessible
    And check peaceful
    And check spaces
    And check hearing
    And check intent
    And check open minds
    And check learning
    And click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And click the 'Next' button
    Then I should see 'Which languages do you speak?'

    When I click the 'Next' button
    Then I should see 'Do you participate in a community bicycle project?'

    When I click the 'No' button
    Then I should see 'In which city or town are you based?'

    When I fill in my location with 'Brooklyn'
    And click the 'Next' button
    Then I should see 'Did you mean Brooklyn, New York, United States?'

    When I click the 'Yes' button
    Then I should see 'Are you willing to be a housing provider?'
    
    When I click the 'Yes' button
    Then I should see 'Are you attending the conference?'

    When I click the 'No' button
    Then I should see 'What is your address?'

    When I enter my address
    And click the 'Next' button
    Then I should see 'What is your phone number?'
    
    When I enter my phone number
    And click the 'Next' button
    Then I should see 'Bed and Couch Space'

    When I fill in bed space with '2'
    And click the 'Next' button
    Then I should see 'Floor Space'

    When I fill in floor space with '8'
    And click the 'Next' button
    Then I should see 'Tent Space'

    When I click the 'Yes' button
    Then I should see 'Housing Start Date'

    When I click on the '25' button
    Then I should see 'Housing End Date'

    When I click on the '11' button
    Then I should see 'House Info and Rules'

    When I enter some info
    And click the 'Next' button
    Then I should see 'Information for organizers'

    When I fill in other with 'We have children in our household'
    And click the 'Next' button

    Then I should see 'Your registration is complete'
    And I should see my address
    And I should see 'We have children in our household'

  Scenario: Attendees can enter incorrect data and fix it
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And there is an organization named 'Coopérative La Bikery Cooperative' in Moncton
    And 'joe@bikebike.org' is registered
    And 'sally@bikebike.org' is registered
    And 'Jesse@bikebike.org' is registered
    And 'joe@bikebike.org' and 'sally@bikebike.org' are companions
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address as 'me@bikebike.org'
    And press confirm email
    Then I should see 'Check your spam box'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Policy'
    And I should see 'The Agreement'
    And see 'Ensuring that all attendees feel welcome, safe, and respected at all times is especially important to us all'

    When I click on the 'I Agree' button
    Then I should see 'Read each statement carefully'

    When I check commitment
    And click the 'I Agree' button
    Then I should see 'Read each statement carefully'

    When check respect
    And check empowerment
    And check accessible
    And check peaceful
    And check spaces
    And check hearing
    And check intent
    And check open minds
    And check learning
    And click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I click the 'Next' button
    Then I should see 'Provide us with a name'

    When I enter my name
    And click the 'Next' button
    Then I should see 'Which languages do you speak?'

    When I uncheck 'English'
    And I click the 'Next' button
    Then I should see 'Select at least one language'

    When I click the 'Next' button
    Then I should see 'Do you participate in a community bicycle project?'

    When I click the 'Yes' button
    Then I should see 'In which city or town is your organization based?'

    When click the 'Next' button
    Then I should see 'Enter a location'

    When I fill in my location with 'fhqwhgads'
    And click the 'Next' button
    Then I should see 'We could not find a city'

    When I fill in my location with 'Moncton'
    And click the 'Next' button
    And click the 'Yes' button
    Then I should see 'Which organization are you a member of?'

    When I click the 'None of the above' button
    Then I should see 'What is the name of your organization?'

    When I click the 'Next' button
    Then I should see 'Enter the name of your organization'

    When I fill in the name with 'Coopérative La Bikery Cooperative'
    And click the 'Next' button
    Then I should see 'Organization Address'

    When click the 'Next' button
    Then I should see 'Enter an address'

    When I fill in the address with '120 Assomption Blvd'
    And click the 'Next' button
    Then I should see 'Organization Email'

    When I click the 'Next' button
    Then I should see 'email address is required'
    
    When I fill in the email with 'me@bikebike.org'
    And I click the 'Next' button
    Then I should see 'email address matches your personal email address'

    When I fill in the email with 'labikery@bikebike.org'
    And click the 'Next' button
    Then I should see 'Organization Mailing Address'

    When I fill in the mailing address with ''
    And click the 'Next' button
    Then I should see 'Enter your organization's mailing address'

    When I fill in the mailing address with '120 Assomption Blvd'
    And click the 'Next' button
    Then I should see 'Arrival Date'

    When I click the '31' button
    And click the '30' button
    Then I should see 'departure date that is before your arrival'

    When I click the '4' button
    Then I should see 'Do you need a place to stay in Brooklyn?'

    When I click on the 'Yes, I would like to place to stay' button
    Then I should see 'Housing Companion'

    When I click on the 'Yes' button
    And click the 'Next' button
    Then I should see 'Enter an email address'

    When I fill in the email with 'joe@bikebike.org'
    And click the 'Next' button
    Then I should see 'already has a companion'

    When I fill in the email with 'jesse@bikebike.org'
    And click the 'Next' button
    Then I should see 'Your companion has completed their registration'
    And see 'What are your eating habits?'

    When click on 'I eat meat and dairy'
    And I click on the 'Yes' button
    And I click on the 'Yes' button
    And click the 'Next' button
    And I click on 'pay now with PayPal'
    And fill in the custom value with '-1'
    And click the 'Custom amount' button
    Then I should see 'Enter a positive amount'

    When fill in the custom value with '1'
    But my payment status will be 'Denied'
    And click the 'Custom amount' button
    And click the 'Confirm' button
    Then I should see 'Your payment was denied'
    And I should see 'Registration Fee Amount'

    When fill in the custom value with '1'
    But my payment status will be 'Error'
    And click the 'Custom amount' button
    And click the 'Confirm' button
    Then I should see 'An unexpected error occurred'
    And I should see 'Registration Fee Amount'

    When fill in the custom value with '1'
    And click the 'Custom amount' button
    And click the 'Cancel' button
    Then I should see 'Your payment was cancelled'
    And I should see 'Registration Fee Amount'

    When fill in the custom value with '1'
    And my payment status will be 'Pending' 
    And click the 'Custom amount' button
    And click the 'Confirm' button
    Then I should see 'Your payment is currently pending'
    And I should see 'Your registration is complete'

Scenario: Housing providers can enter incorrect data and fix it
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is open
    And I am on the landing page

    Then I should see a 'Register' link
    
    When I click the 'Register' link
    Then I should be on the register page
    And I should see 'Registration is now open'

    When I enter my email address
    And press confirm email
    Then I should see 'Check your spam box'
    And I should get a 'confirmation' email

    When I click on the 'Confirm' link in the email
    Then I should see 'Policy'
    And I should see 'The Agreement'
    And see 'Ensuring that all attendees feel welcome, safe, and respected at all times is especially important to us all'

    When I check commitment
    And check respect
    And check empowerment
    And check accessible
    And check peaceful
    And check spaces
    And check hearing
    And check intent
    And check open minds
    And check learning
    And click on the 'I Agree' button
    Then I should see 'What is your name?'

    When I enter my name
    And click the 'Next' button
    Then I should see 'Which languages do you speak?'

    When I click the 'Next' button
    Then I should see 'Do you participate in a community bicycle project?'

    When I click the 'No' button
    Then I should see 'In which city or town are you based?'

    When I fill in my location with 'Brooklyn'
    And click the 'Next' button
    Then I should see 'Did you mean Brooklyn, New York, United States?'

    When I click the 'Yes' button
    Then I should see 'Are you willing to be a housing provider?'
    
    When I click the 'Yes' button
    Then I should see 'Are you attending the conference?'

    When I click the 'No' button
    Then I should see 'What is your address?'

    When I fill in my address with ''
    And click the 'Next' button
    Then I should see 'Enter an address'
    
    When I enter my address
    And click the 'Next' button
    Then I should see 'What is your phone number?'
    
    When I fill in my phone with '911'
    And click the 'Next' button
    Then I should see 'A valid phone number is required'

    When I enter my phone number
    And click the 'Next' button
    Then I should see 'Bed and Couch Space'

    When I fill in bed space with ''
    And click the 'Next' button
    Then I should see 'Enter the amount of bed or couch space'

    When I fill in bed space with '2'
    And click the 'Next' button
    Then I should see 'Floor Space'

    When I fill in floor space with ''
    And click the 'Next' button
    Then I should see 'Enter the amount of floor space'

    When I fill in floor space with '8'
    And click the 'Next' button
    Then I should see 'Tent Space'

    When I click the 'Yes' button
    Then I should see 'Housing Start Date'

    When I click the '31' button
    And click the '30' button
    Then I should see 'end date that is before your start date'

    When I click the '4' button
    Then I should see 'House Info and Rules'

    When I click the 'Next' button
    Then I should see 'Provide your guests with information'

    When I enter some info
    And click the 'Next' button
    Then I should see 'Information for organizers'

    When I click the 'Next' button
    Then I should see 'Your registration is complete'

Scenario: Registration is not accessible after registration is closed
    Given there is an upcoming conference in 'Brooklyn NY'
    And registration is closed
    And I am on the registration page

    Then I should see 'You may need to be signed in to access this page'
