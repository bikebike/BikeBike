# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conference_registration_response do
    conference_registration_id 1
    registration_form_field_id 1
    data "MyText"
  end
end
