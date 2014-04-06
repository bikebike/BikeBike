# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :workshop_facilitator do
    user_id 1
    workshop_id 1
    role "MyString"
  end
end
