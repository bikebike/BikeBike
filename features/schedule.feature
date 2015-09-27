Feature: Workshop Page
	In order to facilitate and attend workshops
	As a visitor

	Scenario: View published schedule
		Given There is an upcoming conference in Boise ID
		And Registration is open

		And a location named The Shop exists
		
		And a workshop titled Bikes and Beers exists
		And the workshop is scheduled for day 2 at 9:00 at The Shop

		And a workshop titled Bike Art exists
		And the workshop is scheduled for day 2 at 12:00 at The Shop
		
		And a workshop titled Advocacy Now! exists
		And the workshop is scheduled for day 2 at 14:00 at The Shop
		
		And a workshop titled Public Outreach exists
		And the workshop is scheduled for day 2 at 21:00 at The Shop

		And the workshop schedule is published

		And I am on the landing page
		Then I see the Bike!Bike! logo
