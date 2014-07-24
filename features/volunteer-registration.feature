Feature: Volunteer Registration
	In order to register to volunteer at the latest Bike!Bike!
	As a visitor

	@javascript
	Scenario: Register as volunteer
		Given There is an upcoming conference in Moncton NB
		And Registration is open

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with example@example.com
		And I press register

		And I fill in my firstname with Francis
		And I fill in my lastname with Bacon
		And I fill in my username with Bacon
		And I check is_volunteer
		And I press next
		
		Then I see Contact Information
		And I fill in address with 1234 Some St.
		And I fill in phone number with 555-555-5555
		
		Then I see Do you have housing
		And I fill in beds with 0
		And I fill in couch_space with 5
		And I fill in tents with 2

		Then I see Anything else
		And I fill in other with So excited!
		
		And I press next

		Then I should be registered for the conference
		And my registration should not be confirmed
		And I should get a confirm email
		And in the email I should see please confirm your registration
		And in the email I should see a confirmation link registration

		When I go to the confirmation page
		Then I should see Thanks for completing your registration
		And my registration is complete
		And my registration is completed
