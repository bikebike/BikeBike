
Given /^(?:(?:that )?there is )?an? (upcoming|past)( regional)? conference(?: in '(.+)')?$/i do |when_, is_regional, location|
  location ||= 'Brooklyn NY' # this will set up our mocks to use a valid poster
  TestState.last_conference = FactoryGirl.build("#{when_}#{is_regional ? '_regional' : ''}_conference".to_sym)
  TestState.last_conference.city = City.search(location)
  TestState.last_organization = create_org(nil, location)
  TestState.last_conference.organizations << TestState.last_organization

  # generate the slug
  TestState.last_conference.save!

  # set the poster
  poster = File.join(Rails.root, 'features', 'support', 'assets', 'images',
          'posters', "#{TestState.last_conference.slug}.png")
  TestState.last_conference.poster = Rack::Test::UploadedFile.new(poster) if File.exist?(poster)
  TestState.last_conference.save!
end

Given /^there is an organization named '(.+)' in (.+)$/ do |org_name, location|
  TestState.last_organization = create_org(org_name, location)
end

Given /^(?:the conference |it )has no (poster|date)$/i do |field|
  if field == 'date'
    TestState.last_conference.start_date = nil
    TestState.last_conference.end_date = nil
  else
    TestState.last_conference.send("#{field}=".to_sym, nil)
  end

  TestState.last_conference.save!
end

Given /^(?:the conference |it )?is not (featured|public)$/i do |field|
  TestState.last_conference.send("is_#{field}=".to_sym, false)
  TestState.last_conference.save!
end

Given /^the conference accepts housing providers that live within (\d+)(mi|km)$/i do |number, unit|
  TestState.last_conference.provider_conditions = { 'distance' => {'number' => number.to_i, 'unit' => unit } }
  TestState.last_conference.save!
end

Given /^the conference accepts paypal$/i do
  TestState.last_conference.paypal_email_address = Forgery(:internet).email_address
  TestState.last_conference.paypal_username = Forgery(:internet).user_name
  TestState.last_conference.paypal_password = Forgery(:basic).password
  TestState.last_conference.paypal_signature = Forgery(:basic).password
  TestState.last_conference.save!
end

Then /^I am( not)? a member of (.+)$/i do |state, org_name|
  user = nil
  should_be = !(state =~ / not/)
  org = Organization.find_by(:name => org_name)
  if should_be
    org.should be
    org.users.should be
  elsif org.nil? || org.users.nil?
    return
  end
  org.users.each { |u|
    if u.email == TestState.last_email_entered
      user = u
    end
  }
  user.send(should_be ? 'should' : 'should_not', be)
end

Given /^the event locations are:$/i do |table|
  table.hashes.each do |location|
    create_location(headers_to_attributes(location))
  end
end

Given /^the workshop times are:$/i do |table|
  blocks = []
  wday = TestState.last_conference.start_date.wday
  table.hashes.each do |block|
    blocks << {
      'time'   => string_to_time(block['Time']).to_s,
      'length' => string_to_time_length(block['Length']).to_s,
      'days' => block['Days'].split(/\s*,\s*/).map { |day| str_to_wday(day).to_s }
    }
  end
  TestState.last_conference.workshop_blocks = blocks
  TestState.last_conference.save!
end

Given /^the schedule on (.+) is:$/i do |day, table|
  @locations = {}
  conference_day = str_to_wday(day)

  table.hashes.each_with_index do |slot, block|
    slot.each do |location_title, workshop_title|
      location = (@locations[location_title] ||= EventLocation.find_by_title(location_title))
      workshop = create_workshop(workshop_title)
      workshop.block = {
          'day'   => conference_day,
          'block' => block
        }
      workshop.event_location_id = location.id
      workshop.save!
    end
  end
end
