Given /^((?:I )?have|there is) a workshop (?:named |titled )?'(.+?)'$/ do |owner, title|
  if owner =~ /^there is$/
    owner = create_user
    create_registration(owner)
  else
    owner = TestState.my_account
  end
  create_workshop(title, owner)
end

Given /^(?:it|'(.+?)') is (not )?looking for facilitators$/ do |title, negate|
  workshop = title.present? ? TestState.last_workshop : Workshop.find_by_title(title)
  workshop.needs_facilitators = !negate
  workshop.save!
end

Given /^(?:I am|'(.+)' is) facilitating(?: '(.+?)')?$/ do |user, title|
  workshop = title.present? ? Workshop.find_by_title(title) : TestState.last_workshop
  user = user.present? ? get_user(user) : TestState.my_account
  WorkshopFacilitator.create(
      user_id: user.id,
      workshop_id: workshop.id,
      role: :collaborator
    )
end

Then /^(?:I )?save (?:my |the )workshop$/i do
  title = find('[name=title]').value
  click_button('save')
  TestState.last_workshop = Workshop.order('created_at DESC').first
end

Then /^(?:I )?(view|edit|delete) (?:my |the )workshop$/i do |action|
  if action == 'view'
    visit "/conferences/#{TestState.last_conference.slug}/workshops/#{TestState.last_workshop.id}"
  else
    visit "/conferences/#{TestState.last_conference.slug}/workshops/#{TestState.last_workshop.id}/#{action}"
  end
end

Given /^the workshop is scheduled for day (\d+) at (\d\d?):(\d\d) at (.+)$/i do |day, hour, minute, location|
  TestState.last_workshop.start_time = TestState.last_conference.start_date.change({hour: hour.to_i, min: minute.to_i}) + (day.to_i - 1).days
  TestState.last_workshop.end_time = TestState.last_workshop.start_time + 1.5.hours
  TestState.last_workshop.event_location_id = EventLocation.find_by_title(location).id
  TestState.last_workshop.save!
end

Given /^the workshop schedule is (not )?published$/i do |is_not_published|
  TestState.last_conference.workshop_schedule_published = is_not_published ? false : true
  TestState.last_conference.save!
end

Given /^(?:I )?have created a workshop titled (.+)(?: with (\d+) facilitators)?$/i do |title, facilitator_count|
  workshop = Workshop.new
  workshop.conference_id = TestState.last_conference.id
  workshop.title = title ? title.gsub(/^\s*titled\s*(.*?)\s*$/, '\1') : Forgery::LoremIpsum.sentence({:random => true}).gsub(/\.$/, '').titlecase
  workshop.info = Forgery::LoremIpsum.paragraph({:random => true})
  workshop.locale = :en
  workshop.save
  WorkshopFacilitator.create(user_id: TestState.my_account.id, workshop_id: workshop.id, role: :creator)
  (1..(facilitator_count || '0').to_i).each do |i|
    username = Forgery::LoremIpsum.word({:random => true})
    user = User.create(firstname: username, email: "#{username}@bikebike.org")
    WorkshopFacilitator.create(user_id: user.id, workshop_id: workshop.id, role: :collaborator)
  end
  TestState.last_workshop = workshop
end

Given /^(.+?) (?:person is |people are )?interested(?: in '(.+?)')?$/i do |interested, title|
  workshop = title.present? ? Workshop.find_by_title(title) : TestState.last_workshop
  str_to_num(interested).times do
    user = create_user
    WorkshopInterest.create(workshop_id: workshop.id, user_id: user.id)
  end
end

Given /^(\d+) (?:person has |people have )?requested to facilitate (?:the |my )?workshop$/i do |request_count|
  (1..(request_count || '0').to_i).each do |i|
    username = Forgery::LoremIpsum.word({:random => true})
    user = User.create(firstname: username, email: "#{username}@bikebike.org")
    WorkshopFacilitator.create(user_id: user.id, workshop_id: TestState.last_workshop.id, role: :requested)
  end
end

Given /^'(.+)' has requested to facilitate (?:the |my )?workshop$/i do |username|
  user = get_user(username)
  WorkshopFacilitator.create(user_id: user.id, workshop_id: TestState.last_workshop.id, role: :requested)
end

Given /^(.+) is (?:also )?facilitating (?:the |my )?workshop$/i do |username|
  user = User.create(firstname: username, email: "#{username.gsub(/\s+/, '.')}@bikebike.org")
  WorkshopFacilitator.create(user_id: user.id, workshop_id: TestState.last_workshop.id, role: :collaborator)
end

Then /^(?:I )?(approve|deny) the facilitator request from (.+)$/i do |action, username|
  user = User.find_by_firstname(username)
  visit "/conferences/#{TestState.last_conference.slug}/workshops/#{TestState.last_workshop.id}/facilitate_request/#{user.id}/#{action}/"
end

Then /^(?:I )?(?:should )?(not )?see (.+) workshops?(?: in total)?(?: under '(.+?)')?$/i do |negate, number, heading|
  if heading
    parent = parent_element(element_with_text(heading))
  else
    parent = page
  end
  compare(number, parent.all('.workshop-list > li, #schedule-preview .workshop').size, negate)
end
