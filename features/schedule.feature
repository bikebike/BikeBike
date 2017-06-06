Feature: Conference Schedule

  Scenario: View published schedule
    Given that there is an upcoming conference
    And registration is open
    And I am logged in
    And registered

    And the event locations are:
      | Title      | Address            |
      |  The Shop  |  1027 Flatbush Ave |
      |  The Co-op |  1415 Cortelyou Rd |

    And the workshop times are:
      | Time   | Length             | Days                |
      |   9:00 |  1 hour 30 minutes |  Tuesday, Wednesday |
      |  10:30 |  1 hour 30 minutes |  Tuesday, Wednesday |
      |   1:30 |  1 hour 30 minutes |  Tuesday, Wednesday |
      |   3:00 |             1 hour |  Tuesday, Wednesday |

    And the schedule on Tuesday is:
      | The Shop                         | The Co-op                        |
      |  How to teach “hands off”        |  Volunteer Retention and Burnout |
      |  Reaching New Immigrants         |  Winter Riding Skill-share       |
      |  Recycled Bike Art!              |  Yoga for Cyclists               |
      |  Vanquishing the Storage Monster |  Battlefield: Consensus!         |

    And the schedule on Wednesday is:
      | The Shop                             | The Co-op                     |
      |  Bike Advocacy/Working with the City |  Confronting car culture      |
      |  Bike Book Club!                     |  Mobile Repair Clinic         |
      |  Bike Sharing!                       |  Recycled bike art            |
      |  Classes, Workshops, Space           |  Software developers exchange |

    And the workshop schedule is not published
    And I am on the conference page

    Then I should see 'Bike!Bike! 2025'
    And see 'Proposed Workshops'
    And see 'Bike Sharing!'
    But I should not see 'Schedule'
    And not see 'Tuesday'
    And I should see 16 workshops under 'Proposed Workshops'

    When the workshop schedule is published
    And I refresh the page
    Then I should see 'Schedule'
    And see 'Tuesday'
    And see 'Wednesday'
    And see 'Bike Sharing!'
    And I should see 16 workshops under 'Schedule'
    But I should not see 'Proposed Workshops'
    And not see 'Monday'
    And not see 'Thursday'
    And not see 'Flatbush Ave'

    When I click on 'Reaching New Immigrants' link
    Then I should see 'The Shop'
    And see '1027 Flatbush Ave'
    And see 'Details'
    And see 'Close'

    When I click on the 'Close' button
    Then I should not see 'Flatbush Ave'
    But I should see 'Battlefield: Consensus!'

    When I click on 'Battlefield: Consensus!'
    Then I should see 'The Co-op'
    And see '1415 Cortelyou Rd'

    When I click on the '1415 Cortelyou Rd' link
    Then I should be on a google maps page
