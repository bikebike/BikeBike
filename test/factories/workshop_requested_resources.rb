# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :workshop_requested_resource do
    workshop_id 1
    workshop_resource_id 1
    status "MyString"
  end
end
