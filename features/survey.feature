Feature: Survey

  Scenario: Take the post-conference survey
    Given that there is a past conference
    And registration is closed
    And I am logged in
    And registered
    And I am checked in
    And I am on the registration page
    Then I should see 'Please share your feelings and experiences'

    When I click on 'Take the survey now'
    Then I should see 'Please share your feelings and experiences from this year's Bike!Bike!'
    But I should not see 'Thank you for taking the post-conference survey'

    When I click on 'This was my first time attending'
    And click on 'Likely'
    And set housing to satisfied under services
    And set bike to NA under services
    And set food to unsatisfied under services
    And set schedule to neutral under services
    And set events to very satisfied under services
    And set website to very unsatisfied under services
    And enter a services comment as 'The website sucks'
    And enter an experience as 'Fun'
    And enter improvement ideas as 'No idea'
    And click 'Submit'

    Then I should see 'Thank you for taking the post-conference survey'

  Scenario: Try to take the post-conference survey when not checked in
    Given that there is a past conference
    And registration is closed
    And I am logged in
    And registered
    And I am not checked in
    And I am on the conference survey page

    Then I should see 'you did not check in'
    Then I should not see 'Please share your feelings and experiences from this year's Bike!Bike!'
    But I should not see 'Thank you for taking the post-conference survey'

    When I go to the registration page
    Then I should not see 'Please share your feelings and experiences'
