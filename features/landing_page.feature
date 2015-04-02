Feature: Landing Page
	In order to learn about Bike!Bike!
	As a visitor

	Scenario: See a more info link
		Given There is an upcoming conference in Halifax NS
		And I am on the landing page
		#Then I see the Bike!Bike! logo
		#And I see the Conferences menu item
		#And I see the Organizations menu item
		#And I see the Resources menu item
		#And I see Halifax
		#And I see More Info

	Scenario: See a register link
		Given There is an upcoming conference in Halifax NS
		And Registration is open
		And I am on the landing page
		#Then I see the Bike!Bike! logo
		#And I see the Conferences menu item
		#And I see the Organizations menu item
		#And I see the Resources menu item
		#And I see Halifax
		#And I see a Register Now link
