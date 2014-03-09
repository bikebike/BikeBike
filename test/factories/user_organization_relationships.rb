# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :user_organization_relationship do
    user_id 1
    organization_id 1
    relationship "MyString"
  end
end
