
Given /^(?:I am |'(.+)' is )?registered(?: for the conference)?$/i do |username|
  create_registration(username.present? ? get_user(username) : TestState.my_account)
end

Given /^I am (not )?checked in?$/i do |do_not_check_in|
  unless do_not_check_in
    TestState.my_registration.data ||= {}
    TestState.my_registration.data['checked_in'] ||= DateTime.now
    TestState.my_registration.save!
  end
end

Given /^(.+) and (.+) are companions$/i do |user1, user2|
  u1 = get_user(user1.gsub(/'/, ''))
  u2 = get_user(user2.gsub(/'/, ''))
  registration1 = ConferenceRegistration.find_by(user_id: u1.id, conference_id: TestState.last_conference.id)
  registration1.housing_data['companion'] = { 'id' => u2.id }
  registration1.save

  registration2 = ConferenceRegistration.find_by(user_id: u2.id, conference_id: TestState.last_conference.id)
  registration2.housing_data['companion'] = { 'id' => u1.id }
  registration2.save
end

Given /^(?:I )?have paid( \$?\d+|\$?\d+\.\d+)? for registration$/i do |amount|
  TestState.my_registration.registration_fees_paid = amount ? amount.to_f : 50.0
  TestState.my_registration.save!
end

Given /^my payment status will be '(Completed|Pending|Denied|Error)'$/i do |status|
  TestState.my_registration.data ||= {}
  TestState.my_registration.data['payment_status'] = status
  TestState.my_registration.save!
end

Then /^my registration should( not)? be (confirmed|completed?|paid)$/i do |state, field|
  ConferenceRegistration.find_by!(email: TestState.last_email_entered).
    send(field == 'confirmed' ? 'is_confirmed' : (field == 'paid' ? 'registration_fees_paid' : field)).
    send(state =~ / not/ ? 'should_not' : 'should', be)
end

Then /^I should (not )?be registered for the conference$/i do |state|
  if state && state.strip == 'not'
    TestState.my_registration.should be_nil
  else
    TestState.my_registration.should_not be_nil
  end
end

When /^(?:I )?(finish|cancel|don't finish) (?:(?:with )?(?:paypal|the payment))$/i do |action|
  TestState.my_registration ||= ConferenceRegistration.find_by(user_id: TestState.my_account.id, conference_id: TestState.last_conference.id)
  TestState.my_registration.payment_confirmation_token = 'token'
  
  unless action == 'cancel'
    info = YAML.load(TestState.my_registration.payment_info) || {}
    info[:status] = action == 'finish' ? 'Completed' : 'Incomplete'
    TestState.my_registration.payment_info = info.to_yaml
  end
  
  TestState.my_registration.save!
  visit send("register_paypal_#{action == 'cancel' ? 'cancel' : 'confirm'}_path".to_sym, TestState.last_conference.slug, :paypal_confirm, 'token', amount: YAML.load(TestState.my_registration.payment_info)[:amount])
end

Given /^a workshop( titled .+)? exists?$/i do |title|
  workshop = Workshop.new
  workshop.conference_id = TestState.last_conference.id
  workshop.title = title ? title.gsub(/^\s*titled\s*(.*?)\s*$/, '\1') : Forgery::LoremIpsum.sentence({random: true}).gsub(/\.$/, '').titlecase
  workshop.info = Forgery::LoremIpsum.paragraph({random: true})
  workshop.locale = :en
  workshop.save
  username = Forgery::LoremIpsum.word({random: true})
  user = User.create(firstname: username, email: "#{username}@bikebike.org")
  WorkshopFacilitator.create(user_id: user.id, workshop_id: workshop.id, role: :creator)
  TestState.last_workshop = workshop
end

Given /^registration is (open|closed)$/i do |status|
  TestState.last_conference.registration_status = status
  TestState.last_conference.save!
end
