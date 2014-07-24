Feature: Translation Pages
	In order to Translate Bike!Bike!
	As a visitor

	Scenario: Visit Translation List Page
		Given I am on the English site
		And I am on the translation list page
		Then I see Translations
		And I see list
		And I see active
		And I see inactive

	Scenario: Visit English Translation Page
		Given I am on the English site
		And I am on the english translations page
		Then I see language translations
