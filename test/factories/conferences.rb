# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conference do
    title "MyString"
    slug "MyString"
    start_date "2014-03-01 13:21:57"
    end_date "2014-03-01 13:21:57"
    info "MyText"
    poster "MyString"
    banner "MyString"
    workshop_schedule_published false
    registration_open false
    meals_provided false
    meal_info "MyText"
    travel_info "MyText"
    conference_type ""
  end
end
