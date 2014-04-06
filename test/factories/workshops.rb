# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :workshop do
    title "MyString"
    slug "MyString"
    info "MyText"
    conference_id 1
    workshop_stream_id 1
    workshop_presentation_style 1
    min_facilitators 1
    location_id 1
    start_time "2014-03-13 20:56:47"
    end_time "2014-03-13 20:56:47"
  end
end
