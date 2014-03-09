# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conference_registration do
    conference_id 1
    user_id 1
    is_attending "MyString"
  end
end
