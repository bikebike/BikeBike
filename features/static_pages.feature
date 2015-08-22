Feature: Static Pages
	In order to learn about Bike!Bike!
	As a visitor

	Scenario: Read the about page
		Given There is an upcoming conference in Halifax NS
		And I am on the about page

	Scenario: Read the policy page
		Given There is an upcoming conference in Halifax NS
		And I am on the policy page

	Scenario: See a 404 page
		Given There is an upcoming conference in Halifax NS
		And I am on a 404 error page
