Feature: Landing Page
	In order to learn about Bike!Bike!
	As a visitor

	Scenario: See a more info link
		Given There is an upcoming conference in Halifax NS
		And I am on the landing page
		Then I see the Bike!Bike! logo

	Scenario: See a register link
		Given There is an upcoming conference in Sackville NB
		And Registration is open
		And I am on the landing page
		And I see a Register link
