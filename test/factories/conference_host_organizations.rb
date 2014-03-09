# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :conference_host_organization do
    conference_id 1
    organization_id 1
    order 1
  end
end
