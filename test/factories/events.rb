# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event do
    title "MyString"
    slug "MyString"
    event_type_id 1
    conference ""
    info "MyText"
    location ""
    start_time "2014-03-15 12:32:41"
    end_time "2014-03-15 12:32:41"
  end
end
