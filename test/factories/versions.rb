# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :version do
    item_type "MyString"
    item_id 1
    event "MyString"
    whodunnit "MyString"
    object "MyText"
    created_at "2014-02-11 19:21:15"
  end
end
