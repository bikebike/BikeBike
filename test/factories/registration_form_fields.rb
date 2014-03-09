# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :registration_form_field do
    title "MyString"
    help "MyText"
    required false
    field_type "MyString"
    options "MyString"
    is_retired false
  end
end
