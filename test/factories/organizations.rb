# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :organization do
    name "MyString"
    slug "MyString"
    email_address "MyString"
    url "MyString"
    year_founded 1
    info "MyText"
    logo "MyString"
    avatar "MyString"
    requires_approval false
    secret_question "MyString"
    secret_answer "MyString"
    location_id 1
    user_organization_replationship_id 1
  end
end
