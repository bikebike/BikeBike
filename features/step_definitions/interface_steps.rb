Given(/^I am on the (.+) page$/) do |page_name|
	visit path_to(page_name.to_sym)
end

Given(/^I am on the (.+) site$/) do |language|
	ApplicationController::set_host (get_language_code(language) + '.bikebike.org')
end

Given(/^I am in (.+)$/) do |location|
	ApplicationController::set_location (location)
end

When(/^I go to the (.+) page$/) do |page_name|
	visit path_to(page_name.to_sym)
end

When(/^(I )?(finish|cancel) (paying|(the )?payment)$/) do |a, action, b, c|
	visit path_to((action == 'finish' ? 'confirm' : action) + ' payment')
end

Given(/^There is an upcoming conference( in .+)?$/) do |location|
	@last_conference = FactoryGirl.create(:upcoming_conference)
	if location
		@org = create_org(nil, location)
		@last_conference.organizations << @org
		@last_conference.save!
	end
end

Given(/^an organization( named .+)? exists( in .+)?$/) do |name, location|
	if location =~ /every country/i
		Carmen::World.instance.subregions.each { |country|
			#puts "#{country.code}"

			if country.subregions?
				country.subregions.each { |region|
					org = Organization.new(name: rand(36**16).to_s(36), slug: rand(36**16).to_s(36))#create_org#(Forgery::LoremIpsum.sentence)
					org.locations << Location.new(city: 'City', country: country.code, territory: region.code)
					org.save!
				}
			else
				org = Organization.new(name: rand(36**16).to_s(36), slug: rand(36**16).to_s(36))#create_org#(Forgery::LoremIpsum.sentence)
				org.locations << Location.new(city: 'City', country: country.code)
				org.save!
			end
		}
	else
		create_org(name ? name.gsub(/^\s*named\s+(.*?)\s*$/, '\1') : nil, location ? location.gsub(/^\s*in\s+(.*?)\s*$/, '\1') : nil)
	end
end

Given(/^Registration is (open|closed)$/) do |status|
	@last_conference.registration_open = (status == 'open')
	@last_conference.save!
end

Then(/^I (should )?see (.+)$/) do | a, item |
	if /(the )?Bike!Bike! logo$/ =~ item
		expect(page).to have_selector('svg.logo')
	elsif /(the|a)?\s?(.+) menu item$/ =~ item
		within('#main-nav') { expect(page).to have_link Regexp.last_match(2) }
	elsif /(the|a)?\s?(.+) image$/ =~ item
		expect(page).to have_selector('#'+Regexp.last_match(2)+' img')
	elsif /(the|a)?\s?(.+) link$/ =~ item
		expect(page).to have_link Regexp.last_match(2)
	else
		expect(page).to have_text item
	end
end


##  =======   Forms   =======  ##

Then(/^(I )?click on (.+?)( button| link| which is hidden)?$/) do | a, item, type |
	item = item.gsub(/^\s*(a|the)\s*(.*)$/, '\2')
	if type && type.strip == 'button'
		click_button(item)
	elsif type && type.strip == 'link'
		click_link(item)
	elsif type && type =~ /hidden/
		find('[id$="' + item.gsub(/\s+/, '_') + '"]', :visible => false).click
	else
		page.find_link(item).trigger('click')
	end
end

Then(/^(I )?press (.+)$/) do | a, item |
	click_link_or_button(locate(item))
end

Then(/^I (un)?check (.+)$/) do | state, item |
	if state == 'un'
		uncheck(locate(item))
	else
		check(locate(item))
	end
end

Then(/^I fill in (.+?) with (.+)$/) do | field, value |
	field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
	fill_in(locate(field), :with => value)

	if /email/ =~ field && !(/organization/ =~ field)
		@last_email_entered = value
	end
end

Then(/^(my )?(.+)? should (not )?be set to (.+)$/) do | a, field, should, value |
	field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
	page.find('[id$="' + field.gsub(/\s+/, '_') + '"]').value.send(should.nil? ? 'should' : 'should_not', eq(value))
end

Then(/^(my )?(.+)? should (not )?be checked$/) do | a, field, should |
	field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
	page.find('[id$="' + field.gsub(/\s+/, '_') + '"]').send(should.nil? ? 'should' : 'should_not', be_checked)
end

Then(/^I set (.+?) to (.+)$/) do | field, value |
	field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
	page.find('[id$="' + field.gsub(/\s+/, '_') + '"]', :visible => false).set value
end

Then(/^(I )wait for (.+?) to appear$/) do | a, field |
	count = 0
	element = nil
	while element.nil? && count < 120
		begin element = page.find('[id$="' + field.gsub(/\s+/, '_') + '"]'); rescue; end
		begin element ||= page.find('[id$="' + field.gsub(/\s+/, '_') + '"]', :visible => false); rescue; end
		sleep(1)
		count += 1
	end
end

Then(/^show the page$/) do
	print page.html
	save_and_open_page
end

Then(/^I select (.+?) from (.+)$/) do | value, field |
	select(value, :from => locate(field))
end

##  =======   Emails   =======  ##

Then(/^I should not get an email$/) do
	ActionMailer::Base.deliveries.size.should eq 0
end

Then (/^I should get an? (.+) email$/) do |subject|
	@last_email = ActionMailer::Base.deliveries.last
	if @last_email_entered
		@last_email.to.should include @last_email_entered
	end
	@last_email.subject.should include(subject)
end

Then (/^the email should contain (.+)$/) do |value|
	@last_email.parts.first.body.raw_source.should include(value)
	@last_email.parts.last.body.raw_source.should include(value)
end

Then (/^in the email I should see (.+)$/) do |value|
	if /(an?|the|my) (.+) link/ =~ value
		test = path_to Regexp.last_match(2)
		@last_email.parts.first.body.raw_source.should include(test)
		@last_email.parts.last.body.raw_source.should include(test)
	else
		@last_email.parts.first.body.raw_source.should include(value)
		@last_email.parts.last.body.raw_source.should include(value)
	end
end

Then (/^I should (not )?be registered for the conference$/) do |state|
	@last_registration = ConferenceRegistration.find_by(:email => @last_email_entered)
	if state && state.strip == 'not'
		@last_registration.should be_nil
	else
		@last_registration.should_not be_nil
	end
end

Then (/^my registration (should( not)? be|is( not)?) (confirmed|completed?|paid)$/) do |state, x, y, field|
	ConferenceRegistration.find_by!(:email => @last_email_entered).
		send(field == 'confirmed' ? 'is_confirmed' : (field == 'paid' ? 'payment_info' : field)).
		send(state =~ / not/ ? 'should_not' : 'should', be)
end

Then (/^I am( not)? a user$/) do |state|
	User.find_by(:email => @last_email_entered).
		send(state =~ / not/ ? 'should_not' : 'should', be)
end

Then (/^I am( not)? a member of (.+)$/) do |state, org_name|
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
		if u.email == @last_email_entered
			user = u
		end
	}
	user.send(should_be ? 'should' : 'should_not', be)
end

Then (/^My (.+) should(not )? be (.+)$/) do |field, state, value|
	User.find_by(:email => @last_email_entered).
		send(field.gsub(/\s/, '_')).
		send(state =~ / not/ ? 'should_not' : 'should', eq(value))
end
