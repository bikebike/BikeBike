Feature: Registration Page
	In order to register for Bike!Bike!
	As a visitor

	Scenario: View stats
		Given There is an upcoming conference in Anchorage AK
		And Registration is open
		And I am logged in as someguy@bikebike.org
		And My name is Jeff
		And I am a conference host
		And I am registered for the conference
		And I am on the stats page

		Then I should see Total Registrations

	Scenario: View stats.xls
		Given There is an upcoming conference in Anchorage AK
		And Registration is open
		And I am logged in as someguy@bikebike.org
		And My name is Jeff
		And I am a conference host
		And I am registered for the conference
		And I am on the stats.xls page

	Scenario: Start registration from landing page
		Given There is an upcoming conference in Halifax NS
		And Registration is open
		And a workshop titled My Awesome Workshop exists
		And I am on the landing page
		
		Then I see the Bike!Bike! logo
		And I see a Register link
		And I click on the Register link

		Then I am on the registration page
		And I fill in email with myemail@bikebike.org
		And press register
		
		Then I should get a Confirmation email
		And that email should contain /confirm/
		And I confirm my account
		
		Then I should see Agreement
		And I press policy

		Then I should see name
		And I should see Where are you coming from
		And I should see Arrival
		And I should see Departure
		And I fill in name with John Doe
		And fill in location with Mushaboom, NS
		And enter 2016-01-01 as my arrival
		And enter 2016-01-04 as my departure
		And select en as my language
		And select none as my housing
		And select a small bike
		And choose vegan food
		And press save

		Then I should see Payment
		And I should be registered for the conference
		
		Then I pay 50.0
		And I finish with paypal

		Then I should see confirm
		And I should see 50.00
		Then press paypal confirmed

		Then I should see John Doe
		And I should see Mushaboom, NS
		And I should see January
		And I should see English
		And I should see none
		And I should see Vegan
		And I should see 50.00

	Scenario: Broadcast message
		Given There is an upcoming conference in San Marcos TX
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am a conference host
		And I am registered for the conference
		And I am on the broadcast page

		Then I see the Bike!Bike! logo
		And I should see Subject
		And I fill in subject with My Subject
		And I fill in content with Lorem Ipsum
		And I press test

		Then I should see somebody@bikebike.org

		Then I press preview
		Then I should see Lorem Ipsum
		And I press send

		Then I should see email has been sent
		And I should see Preview
		And I should see My Subject

	Scenario: Edit a conference
		Given There is an upcoming conference in Portland OR
		And Registration is open
		And I am logged in as somebody@bikebike.org
		And My name is John Doe
		And I am a conference host
		And I am registered for the conference
		And I am on the edit conference page
		Then I should see Edit Spanish
