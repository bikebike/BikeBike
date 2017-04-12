Then /^I am( not)? a user$/i do |state|
  TestState.my_account.send(state =~ / not/ ? 'should_not' : 'should', be)
end

Given /^(?:I )?(?:am logged|log) in(?: as '(.+)')?$/i do |email|
  TestState.my_account = get_user(email)
  TestState.last_token = 'test'
  
  attempt_to do
    EmailConfirmation.create(token: TestState.last_token, user_id: TestState.my_account.id)

    attempt_to do
      visit path_to(:confirm)
    end

    first(selector_for('email')).set(TestState.my_account.email)
    begin
      first('.flex-form button').click
    rescue Capybara::Poltergeist::TimeoutError
    end

    begin
      expect(page).to have_link TestState.my_account.name
    rescue
      fail "Error logging in"
    end
  end
end

Given /^(?:I )?(only )?speak (.+)$/i do |only, language|
  TestState.my_account.languages ||= ['en']
  if only
    TestState.my_account.languages = [get_locale(language)]
  else
    TestState.my_account.languages << get_locale(language)
  end
  TestState.my_account.save!
end

Then /^(?:I )?should (not )?be (?:logged|signed) in$/ do |negate|
  expect(logged_in?).to_be !negate
end

When /^(?:I )?log in with facebook$/i do
  visit oauth_callback_path(
    name:  TestState.my_account.firstname,
    email: TestState.my_account.email,
    fb_id: TestState.my_account.fb_id
  )
end

Given /^(?:I )?have a facebook account$/i do
  TestState.my_account = FactoryGirl.build(:user)
  TestState.my_account.fb_id = '1'
end

Given /^(?:I )?am a registered user$/i do
  TestState.my_account.save!
end

Given /^my facebook account has no email address$/ do
  TestState.my_account.email = nil
  TestState.my_account.save! if TestState.my_account.id.present?
end

Given /^my name is '(.+)'$/i do |name|
  TestState.my_account.firstname = name
  TestState.my_account.save! if TestState.my_account.id.present?
end

Given /^(?:I )?am an? (.+)$/i do |role|
  if role == 'conference host'
    org = TestState.last_conference.organizations.first
    org.users ||= Array.new
    org.users << TestState.my_account
    org.save
  else
    case role
    when /(site )?admin(istrator)?/
      role = 'administrator'
    end

    TestState.my_account.role = role
    TestState.my_account.save!
  end
end

Then /^(?:I )?confirm my account$/i do
  TestState.my_account = User.find_user(TestState.last_email_entered)
  TestState.confirmation = EmailConfirmation.where(["user_id = ?", TestState.my_account.id]).order("created_at DESC").first
  visit "/confirm/#{TestState.confirmation.token}"
end

Given /^a user named (.+?)(?: with the email (.+))? exists$/i do |username, email|
  user = User.create(firstname: username, email: email || "#{username.gsub(/\s+/, '.')}@bikebike.org")
end
