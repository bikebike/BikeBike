Feature: Workshops
  Scenario: Registered users can create, edit, delete workshops
    Given there is an upcoming conference
    And registration is open
    And I am logged in
    And registered for the conference
    And on the registration page 

    Then I should see 'Propose a Workshop'
    But I should not see any workshops

    When I click on 'Propose a Workshop'
    Then I should see 'Create a Workshop'
    And see 'Describe your workshop in detail'

    When I enter a title
    And enter some info
    And I check 'Spanish'
    And check 'Projector'
    And check 'Funding'
    And check 'Meeting Room'
    And click the 'Save' button

    Then I should be on my workshop page
    And I should see 'Funding'
    And should see 'Projector'
    And see my title
    And see my info

    When I click on 'Edit'
    Then I should see 'Edit Workshop'
    And see 'Describe your workshop in detail'
    And 'English' should be checked
    And 'Spanish' should be checked
    And 'Projector' should be checked
    And 'Funding' should be checked
    And 'Meeting Room' should be checked
    
    When I check 'Tools'
    And check 'Other'
    And enter the other theme as 'Education'
    And click the 'Save' button

    Then I should be on my workshop page
    And I should see 'Tools'
    And should see 'Education'

    When I click the 'Workshops' link
    Then I should see a workshop

    When I click on the 'More info' link
    Then I should see 'Tools'
    And should see 'Education'

    When I click the 'Delete Workshop' link
    Then I should see 'Deleting a workshop cannot be undone'

    When I click on the 'Cancel' button
    Then I should see 'Tools'
    And should see 'Education'

    When I click the 'Delete Workshop' link
    And click the 'Confirm' button
    Then I should see 'Propose a Workshop'
    But I should not see any workshops

  Scenario: Users can comment on an translate their own workshops
    Given that there is an upcoming conference
    And registration is open
    And I am logged in
    And registered
    And I have a workshop titled 'Bridges to Bicycles'
    And I am on my workshop page

    Then I should see 'Bridges to Bicycles'
    When I click 'Translate into Spanish'
    Then I should see 'Translation of Bridges to Bicycles'

    When I enter my title as 'Puentes a las bicicletas'
    And enter some info
    And click the 'Save' button
    Then my workshop title should be 'Bridges to Bicycles'
    And my Spanish workshop title should be 'Puentes a las bicicletas'
    And I should see 'Bridges to Bicycles'
    
    When I enter a comment
    And I click the 'Add Comment' button
    Then I should see 'less than a minute ago'
    And I should see my comment

    When I click the 'Reply' button
    And enter a reply
    And click the 'Reply' button
    Then I should see my comment
    And see my reply

  Scenario: Users can add facilitators to their workshops
    Given that there is an upcoming conference
    And registration is open
    And I am logged in
    And registered
    And I have a workshop titled 'Applying for 501c3 status'
    And I am on my workshop page

    Then I should see 'Applying for 501c3 status'
    When I enter an email address as 'new-facilitator@bikebike.org'
    And click the '+' button

    Then I should be on my workshop page
    And I should see 'new-facilitator@bikebike.org Unregistered'
    And new-facilitator@bikebike.org should get a 'Confirmation' email
    And new-facilitator@bikebike.org should get a 'You have been added as a facilitator' email

    When I click the 'Remove' link
    Then I should see 'Please Confirm'
    And see 'Are you sure you would like to remove new-facilitator@bikebike.org as a facilitator of this workshop?'

    When I click the 'No' button
    Then I should not see 'Please Confirm'
    But I should see 'new-facilitator@bikebike.org Unregistered'

    When I click the 'Remove' link again
    Then I should see 'Please Confirm'
    And I should see 'Yes'
    And click the 'Yes' button
    Then I should not see 'Please Confirm'
    And I should not see 'new-facilitator@bikebike.org Unregistered'
    But I should see 'Applying for 501c3 status'

  Scenario: Users can approve and deny facilitation requests on their workshops
    Given that there is an upcoming conference
    And registration is open
    And I am logged in
    And registered
    And I have a workshop titled 'Sturmey Archer Hub Repair'
    
    And 'Spartacus' has requested to facilitate my workshop
    And 'Saladin' has requested to facilitate my workshop
    And 'Hadrian' has requested to facilitate my workshop
    
    And 'Spartacus' is registered for the conference
    And 'Saladin' is registered for the conference
    And 'Hadrian' is registered for the conference
    
    And I am on my workshop page

    Then I should see 'Sturmey Archer Hub Repair'
    And I should see 'Spartacus Requested'
    And I should see 'Saladin Requested'
    And I should see 'Hadrian Requested'

    When I click the 'Deny' button beside 'Spartacus'
    Then I should be on my workshop page
    And I should see 'Saladin'
    And I should see 'Hadrian'
    But I should not see 'Spartacus'
    And 'Spartacus' should get a 'Your request to facilitate ‘Sturmey Archer Hub Repair’ has been denied' email

    When I click the 'Approve' button beside 'Saladin'
    Then I should be on my workshop page
    And I should see 'Saladin Collaborator'
    And 'Saladin' should get a 'You have been added as a facilitator of ‘Sturmey Archer Hub Repair’' email

    When I click the 'Approve' button beside 'Hadrian'
    Then I should be on my workshop page
    And I should see 'Hadrian Collaborator'
    And 'Hadrian' should get a 'You have been added as a facilitator of ‘Sturmey Archer Hub Repair’' email

    When I click the 'Remove' button beside 'Hadrian'
    Then I should see 'Please Confirm'
    And see 'Are you sure you would like to remove Hadrian as a facilitator of this workshop?'

    When I click on the 'No' button
    Then I should see 'Hadrian'
    
    When I click the 'Remove' button beside 'Hadrian' again
    Then I should see 'Please Confirm'
    And see 'Are you sure you would like to remove Hadrian as a facilitator of this workshop?'

    When I click on the 'Yes' button
    Then I should not see 'Hadrian'
    
    When I click the 'Transfer Ownership' button beside 'Saladin'
    Then I should see 'Please Confirm'
    And see 'Are you sure you want to transfer ownership to Saladin?'

    When I click the 'No' button
    Then I should see 'Saladin Collaborator'
    
    When I click the 'Transfer Ownership' button beside 'Saladin' again
    Then I should see 'Please Confirm'
    And see 'Are you sure you want to transfer ownership to Saladin?'

    When I click the 'Yes' button
    Then I should not see 'Saladin Collaborator'
    But I should see 'Saladin Owner'

    When I click the 'Leave' button
    Then I should see 'Please Confirm'
    And see 'Are you sure you would like to remove yourself as a facilitator of this workshop?'

    When I click the 'No' button
    Then I should see 'Leave'

    When I click the 'Leave' button again
    Then I should see 'Please Confirm'
    And see 'Are you sure you would like to remove yourself as a facilitator of this workshop?'

    When I click the 'Yes' button
    Then I should not see 'Leave'
    But I should see 'Make a facilitation request'

    When I click the 'Make a facilitation request' button
    Then I should see 'Request to Facilitate ‘Sturmey Archer Hub Repair’'

    When I enter a message
    And click the 'Send' button

    Then 'Saladin' should get a 'Request to facilitate ‘Sturmey Archer Hub Repair’' email
    And I should see 'Your request has been sent'

    When I click the 'View this workshop' button
    Then I should see 'Cancel Request'

    When I click the 'Cancel Request' button
    Then I should see 'Please Confirm'
    And I should see 'Are you sure you would like to cancel your request to become a facilitator of this workshop?'

    When I click the 'No' button
    Then I should still see 'Cancel Request'
    When I click the 'Cancel Request' button again
    And click the 'Yes' button
    Then I should not see 'Cancel Request'
    But I should see 'Make a facilitation request'

  Scenario: Users can add interest to workshops
    Given that there is an upcoming conference
    And registration is open
    And I am logged in
    And registered
    And I have a workshop titled 'Bridges to Bicycles'
    And there is a workshop titled '3-Speed Hubs and the trouble with Sexism'
    And there is a workshop titled 'Bike Polo! Mallet making and game'
    And there is a workshop titled 'Cooperating with for-profit bike shops'
    And there is a workshop titled 'The future of Bike! Bike!'

    And '3-Speed Hubs and the trouble with Sexism' is looking for facilitators
    And I am facilitating 'Bike Polo! Mallet making and game'
    And one person is interested in 'Cooperating with for-profit bike shops'
    And ten people are interested in 'The future of Bike! Bike!'
    And five people are interested in 'Bike Polo! Mallet making and game'

    And I am on the workshops page

    Then I should see seven workshops
    And I should see two workshops under 'Your Workshops'
    And see five workshops under 'All Other Workshops'
    And I should see '3-Speed Hubs and the trouble with Sexism No one is interested in this workshop yet'
    And see 'Bike Polo! Mallet making and game 5 people are interested in this workshop'
    And see 'The future of Bike! Bike! 10 people are interested in this workshop'
    And see 'Cooperating with for-profit bike shops One person is interested in this workshop'

    When I click the '+1' button beside '3-Speed Hubs and the trouble with Sexism'
    Then I should see '3-Speed Hubs and the trouble with Sexism You are interested in this workshop'

    When I click the '+1' button beside 'The future of Bike! Bike!'
    Then I should see 'The future of Bike! Bike! You and 10 others are interested in this workshop'

    When I click the '-1' button beside '3-Speed Hubs and the trouble with Sexism'
    Then I should see '3-Speed Hubs and the trouble with Sexism No one is interested in this workshop yet'

    When I click the '-1' button beside 'The future of Bike! Bike!'
    Then I should see 'The future of Bike! Bike! 10 people are interested in this workshop'

  Scenario: Translators can translate workshops
    Given that there is an upcoming conference
    And registration is open
    And I am logged in
    And registered
    And I speak Spanish
    And there is a workshop titled 'Women and Transgender shop hours'
    And 'Macbeth' is facilitating
    And I am on the workshop page

    Then I should see 'Women and Transgender shop hours'
    When I click 'Translate into Spanish'
    Then I should see 'Translation of Women and Transgender shop hours'

    When I enter my title as 'Horas de las mujeres y de los transexuales'
    And enter some info
    And press save

    Then the Spanish workshop title should be 'Horas de las mujeres y de los transexuales'
    And I should see 'Women and Transgender shop hours'
    And 'Macbeth' should get a 'The translation for ‘Women and Transgender shop hours’ has been modified' email

  Scenario: Users can comment on workshops
    Given that there is an upcoming conference
    And registration is open
    And I am logged in as 'Brunhilda'
    And registered
    And 'Geronimo' is registered
    And I have a workshop titled 'Grant writing and Government Contracts'
    And I am on the workshop page
    
    When in a new session
    Then I log in as 'Geronimo'
    And I visit the workshop page
    And enter a comment as 'Will you be covering Canadian contracts?'
    And click the 'Add Comment' button

    Then I should see 'Will you be covering Canadian contracts?'
    And 'Brunhilda' should get a 'commented' email

    When in a new session
    Then I log in as 'Brunhilda'
    And I visit the workshop page
    And click the 'Reply' button
    And enter a reply as 'If we can find a Canadian facilitator'
    And click the 'Reply' button

    Then I should see 'If we can find a Canadian facilitator'
    And 'Geronimo' should get a 'replied' email
