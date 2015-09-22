Feature: Workshop Page
	In order to facilitate and attend workshops
	As a visitor

	Scenario: Create workshop
		Given There is an upcoming conference in San Marcos TX
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am registered for the conference
		And I am on the registration page

		Then I see the Bike!Bike! logo
		And I see Payment
		And I see Workshops
		And I visit the workshops page

		Then I should see New Workshop
		And I should see Your Workshops
		And I click on New Workshop link

		Then I should see Title
		And I fill in title with My Workshop Title
		And I fill in info with Lorem Ipsum
		And I save the workshop

		Then I should see My Workshop Title
		And I view my workshop
		
		Then I should see Facilitators
		And I should see John Doe creator
		And I should see Edit
		Then I edit the workshop

		Then I fill in title with Super Awesome Workshop
		Then I click the save button

		Then I should see Super Awesome Workshop
		And I should not see My Workshop Title
		
		Then I view my workshop
		Then I delete the workshop
		And I click on the confirm button
		
		Then I should see Your Workshops
		And I should not see My Workshop Title
		And I should not see Super Awesome Workshop

	Scenario: Be the first to like a workshop
		Given There is an upcoming conference in Guadalajara Mexico
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am registered for the conference
		And a workshop exists
		And I view the workshop
		
		Then I should see No one is interested
		Then click on toggle_interest button
		Then I should see You are interested

		Then I click on toggle_interest button
		Then I should see No one is interested

	Scenario: Like a workshop
		Given There is an upcoming conference in Guadalajara Mexico
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am registered for the conference
		And a workshop exists
		And 4 people are interested in the workshop
		And I view the workshop
		
		Then I should see 4 people are interested
		Then click on toggle_interest button
		Then I should see You and 4 others are interested

		Then I click on toggle_interest button
		Then I should see 4 people are interested

	Scenario: Request to facilitate a workshop
		Given There is an upcoming conference in Guadalajara Mexico
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am registered for the conference
		And a workshop exists
		And I view the workshop
		
		Then I click on the Make a facilitation request link
		Then I should see Request to Facilitate

		Then I enter Please let me join as my message
		Then I click the send button

		Then I should see Your request has been sent

	Scenario: Request to facilitate a workshop
		Given There is an upcoming conference in Guadalajara Mexico
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am registered for the conference
		And I have created a workshop titled My Awesome Workshop
		And Joey is also facilitating my workshop
		And Katie has requested to facilitate my workshop
		And Jim has requested to facilitate my workshop
		And a user named Ricardo with the email ricky@bikebike.org exists
		And Joey is registered for the conference
		And Jim is registered for the conference
		And Katie is registered for the conference
		And Ricardo is registered for the conference
		And I view the workshop
		
		Then I should see Joey Collaborator
		And I should see Katie Requested
		And I should see Jim Requested

		Then I approve the facilitator request from Jim
		And I should see Jim Collaborator
		And I should see Katie Requested

		Then I deny the facilitator request from Katie
		And I should see Jim Collaborator
		And I should not see Katie
		
		And I fill in email with ricky@bikebike.org
		And I click the + button
		Then I should see Ricardo Collaborator

		And I fill in email with nicky@bikebike.org
		And I click the + button
		Then I should see nicky@bikebike.org Unregistered
