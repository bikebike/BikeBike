Feature: Registration
	In order to register for the latest Bike!Bike!
	As a visitor

	@javascript
	Scenario: Register as really eager participant
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with goodgodwin@hotmail.com
		And I press register

		And I fill in my firstname with Michael
		And I fill in my lastname with Godwin
		And I fill in my username with Godwin
		And I check is_participant
		And I press next
		
		And I see Do you require housing?
		And I select bed from housing
		And I fill in housing extra with I have a bad back
		
		And I see Do you want to borrow a bike?
		And I select large from loaner bike
		
		And I see Would you like to host a workshop?
		And I select No from workshop host
		
		And I see Anything else
		And I fill in other with I'm coming two months early
		And I should not be registered for the conference

		And I press submit

		Then I should be registered for the conference
		And my registration should not be confirmed
		And I should get a confirm email
		And in the email I should see please confirm your registration
		And in the email I should see a confirmation link
		And I see Who do you Represent

		When I go to the confirmation page
		Then I see Thanks for confirming
		And I see Who do you Represent
		And my registration is confirmed
		But my registration is not complete
		And my registration is not completed

		Then I click on Cool Cats Bikes
		And press next

		Then I should see Thanks for completing your registration
		And my registration is complete
		And my registration is completed
		But my registration is not paid
		
		Then I should get a Thanks email
		And in the email I should see pay the registration donation
		And in the email I should see a pay registration link
		
		When I go to the pay registration page
		Then I see Thanks for completing your registration
		And I see we ask that you pay
		And I see custom amount

		Then I pay 12.34
		Then I should see Your order summary
		
		When I finish with paypal
		Then I should see confirm your payment
		And I should see $12.34
		And I have enough funds
		And I press confirm payment

		Then I should see We'll see you in Moncton
		And my registration is paid

	@javascript
	Scenario: Register as participant with some second thoughts
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named The Bike Bush exists in Musquodoboit Harbour NS
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with shout@me.com
		And I press register

		And I fill in my firstname with Joe
		And I fill in my lastname with Smith
		And I fill in my username with Joey
		And I check is_participant
		And I press cancel

		Then I should see you will lose the infomation you have submitted
		Then I press no
		And I should see Attending as
		And firstname should be set to Joe
		And lastname should be set to Smith
		And username should be set to Joey
		And is_participant should be checked
		And is_volunteer should not be checked

		Then I press cancel
		And press yes
		Then I should see Your registration has been cancelled

	@javascript
	Scenario: Register as participant
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named The Bike Bush exists in Musquodoboit Harbour NS
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with shout@me.com
		And I press register

		And I fill in my firstname with Joe
		And I fill in my lastname with Smith
		And I fill in my username with Joey
		And I check is_participant
		And I press next
		
		And I see Do you require housing?
		And I select couch from housing
		And I fill in housing extra with I'm easy
		
		And I see Do you want to borrow a bike?
		And I select Yes, from loaner bike
		
		And I see Would you like to host a workshop?
		And I select No from workshop host
		
		And I see Anything else
		And I fill in other with Nope
		And I should not be registered for the conference

		And I press submit

		Then I should be registered for the conference
		But my registration should not be confirmed
		And I should get a confirm email
		And I should see Who do you Represent

		But my registration is not complete
		And my registration is not completed

		Then I click on The Bike Bush
		And press next
		And my registration is completed

		Then in the email I should see please confirm your registration
		And in the email I should see a confirmation link registration
		And I am not a user

		When I go to the confirmation page
		And I should see Thanks for completing your registration
		And my registration is confirmed
		And my registration is complete
		And my registration is completed
		And I am a user
		And I am a member of The Bike Bush

	@javascript
	Scenario: Register as eager participant
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with goodgodwin@hotmail.com
		And I press register

		And I fill in my firstname with Michael
		And I fill in my lastname with Godwin
		And I fill in my username with Godwin
		And I check is_participant
		And I press next
		
		And I see Do you require housing?
		And I select bed from housing
		And I fill in housing extra with I have a bad back
		
		And I see Do you want to borrow a bike?
		And I select large from loaner bike
		
		And I see Would you like to host a workshop?
		And I select No from workshop host
		
		And I see Anything else
		And I fill in other with I'm coming two months early
		And I should not be registered for the conference

		And I press submit

		Then I should be registered for the conference
		And my registration should not be confirmed
		And I should get a confirm email
		And in the email I should see please confirm your registration
		And in the email I should see a confirmation link
		And I see Who do you Represent

		When I go to the confirmation page
		Then I see Thanks for confirming
		And I see Who do you Represent
		And my registration is confirmed
		But my registration is not complete
		And my registration is not completed

		Then I click on Cool Cats Bikes
		And press next

		Then I should see Thanks for completing your registration
		And my registration is complete
		And my registration is completed
		But my registration is not paid
		
		Then I should get a Thanks email
		And in the email I should see pay the registration donation
		And in the email I should see a pay registration link
		
		When I go to the pay registration page
		Then I see Thanks for completing your registration
		And I see we ask that you pay
		And I see $25.00

		Then I pay 25.00
		Then I should see Your order summary
		
		When I finish with paypal
		Then I should see confirm your payment
		And I should see $25.00
		And I have enough funds
		And I press confirm payment

		Then I should see We'll see you in Moncton
		And my registration is paid

	@javascript
	Scenario: Register as eager with second thoughts
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with goodgodwin@hotmail.com
		And I press register

		And I fill in my firstname with Michael
		And I fill in my lastname with Godwin
		And I fill in my username with Godwin
		And I check is_participant
		And I press next
		
		And I see Do you require housing?
		And I select bed from housing
		And I fill in housing extra with I have a bad back
		
		And I see Do you want to borrow a bike?
		And I select large from loaner bike
		
		And I see Would you like to host a workshop?
		And I select No from workshop host
		
		And I see Anything else
		And I fill in other with I'm coming two months early
		And I should not be registered for the conference

		And I press submit

		Then I should be registered for the conference
		And my registration should not be confirmed
		And I should get a confirm email
		And in the email I should see please confirm your registration
		And in the email I should see a confirmation link
		And I see Who do you Represent

		When I go to the confirmation page
		Then I see Thanks for confirming
		And I see Who do you Represent
		And my registration is confirmed
		But my registration is not complete
		And my registration is not completed

		Then I click on Cool Cats Bikes
		And press next

		Then I should see Thanks for completing your registration
		And my registration is complete
		And my registration is completed
		But my registration is not paid
		
		Then I should get a Thanks email
		And in the email I should see pay the registration donation
		And in the email I should see a pay registration link
		
		Then I should see Thanks for completing your registration
		And I see we ask that you pay
		And I see payment amount
		And I see submit payment

		Then I fill in payment amount with 12.34
		And press submit payment
		Then I should see Your order summary
		
		When I cancel the payment
		Then I should see Thanks for completing your registration
		And I see we ask that you pay
		And my registration is not paid

	@javascript
	Scenario: Register as workshop host
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named The Bike Bush exists in Musquodoboit Harbour NS
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with scream@me.com
		And I press register

		And I fill in my firstname with Joe
		And I fill in my lastname with Smith
		And I fill in my username with Joey
		And I check is_participant
		And I press next
		
		And I see Do you require housing?
		And I select couch from housing
		And I fill in housing extra with I'm easy
		
		And I see Do you want to borrow a bike?
		And I select Yes, from loaner bike
		
		And I see Would you like to host a workshop?
		And I select Yes from workshop host
		
		And I see Anything else
		And I fill in other with Nope
		And I should not be registered for the conference

		And I press submit

		Then I should be registered for the conference
		But my registration should not be confirmed
		And I should get a confirm email
		And I should see Who do you Represent

		But my registration is not complete
		And my registration is not completed

		Then I click on The Bike Bush
		And press next

		Then I should see Workshop Information
		Then I fill in title with How make your shop more Capitalist
		Then I set info to Lorem Ipsum and Stuff
		Then I select organization management from stream
		Then I select presentation from presentation style
		Then I fill in notes with Down with all the anarchists
		Then press next

		Then in the email I should see please confirm your registration
		And in the email I should see a confirmation link registration

		When I go to the confirmation page
		And I should see Thanks for completing your registration
		And my registration is confirmed
		And my registration is complete
		And my registration is completed

	@javascript
	Scenario: Register with new organization
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named The Bike Bush exists in Musquodoboit Harbour NS
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with example@example.com
		And I press register

		And I fill in my firstname with Emma
		And I fill in my lastname with Smith
		And I fill in my username with Em
		And I check is_participant
		And I press next
		
		And I see Do you require housing?
		And I select couch from housing
		And I fill in housing extra with I'm easy
		
		And I see Do you want to borrow a bike?
		And I select small from loaner bike
		
		And I see Would you like to host a workshop?
		And I select No from workshop host
		
		And I see Anything else
		And I fill in other with Nope
		And I should not be registered for the conference

		And I press submit

		Then I should be registered for the conference
		But my registration should not be confirmed
		And I should get a confirm email
		And I should see Who do you Represent

		But my registration is not complete
		And my registration is not completed

		Then I check add new org
		And I press next

		Then I should see Your Organization Information
		Then I fill in name with The Bike Fridge
		Then I set info to Lorem Ipsum and Stuff
		Then I fill in organization email with info@bikefridge.org
		Then I fill in street with 1044 Mushaboom Road
		Then I fill in city with Mushaboom
		Then I select ca from country
		Then I select ns from territory
		Then press next

		Then in the email I should see please confirm your registration
		And in the email I should see a confirmation link registration

		When I go to the confirmation page
		And I should see Thanks for completing your registration
		And my registration is confirmed
		And my registration is complete
		And my registration is completed
		And I am a member of The Bike Fridge

	@javascript
	Scenario: Lazy participant
		Given There is an upcoming conference in Moncton NB
		And Registration is open
		And an organization named The Bike Bush exists in Musquodoboit Harbour NS
		And an organization named Cool Cats Bikes exists in Sackville NB

		When I go to the landing page
		Then I see a Register Now link
		And I click on the Register Now link
		
		And I fill in my email with example@example.com
		And I press register

		And I press next
		But I see please tell us your name

		Then I fill in my firstname with Emma
		And I press next
		But I see please tell us your name
		
		Then I fill in my lastname with Smith
		And I press next
		But I see attending the conference or volunteering

		Then I check is_participant
		And I press next
		
		Then I select Yes from workshop host
		And press submit

		Then I should be registered for the conference
		But my registration should not be confirmed
		And I should get a confirm email
		And I should see Who do you Represent

		But my registration is not complete
		And my registration is not completed

		Then I press next
		But I see Please select an organization

		Then I click on The Bike Bush
		And press next

		Then I should see Workshop Information
		But press next

		But I should see Please give your workshop a title
		Then I fill in title with Why do I have to give all this info right now?
		And press next
		
		But I should see Please describe your workshop
		Then I set info to Lorem Ipsum and Stuff

		Then I select organization management from stream
		And I select presentation from presentation style
		And press next

		Then I should see Thanks for submitting your registration
		
		Then in the email I should see please confirm your registration
		And in the email I should see a confirmation link registration

		When I go to the confirmation page
		And I should see Thanks for completing your registration
		And my registration is confirmed
		And my registration is complete
		And my registration is completed
		And I am a member of The Bike Bush
		And My firstname should be Emma
		And My lastname should be Smith
		And My username should be Emma Smith
