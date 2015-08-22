Given(/^(I )?(am on |visit )the (.+) page$/) do |a, b, page_name|
	visit path_to(page_name)
end

Given(/^I am on a (.+) error page$/) do |page_name|
	case page_name
	when '404'
		path = '/error_404'
	else
		raise "Unknown error page #{page_name}"
	end
	visit path
end

Given(/^I am on the (.+) site$/) do |language|
	ApplicationController::set_host (get_language_code(language) + '.bikebike.org')
end

Given(/^I am in (.+)$/) do |location|
	ApplicationController::set_location (location)
end

When(/^I go to the (.+) page$/) do |page_name|
	visit path_to(page_name)
end

When(/^(I )?(finish|cancel) ((with )?(paypal|the payment))$/) do |a, action, b, c, d|
	if action != 'cancel'
		@last_registration = ConferenceRegistration.find(@last_registration.id)
		@last_registration.payment_confirmation_token = 'token'
		@last_registration.save!
		url = register_paypal_confirm_path(@last_conference.slug, :paypal_confirm, 'token')
		visit url
	end
end

Then(/^(I )?pay \$?([\d\.]+)$/) do | a, amount |
	button = nil

	paypal_info = YAML.load(File.read(Rails.root.join("config/paypal.yml")))['test'].symbolize_keys
	@last_conference.paypal_username = paypal_info[:username]
	@last_conference.paypal_password = paypal_info[:password]
	@last_conference.paypal_signature = paypal_info[:signature]
	@last_conference.save!

	@last_registration.payment_info = {:payer_id => '1234', :token => '5678', :amount => amount.to_f, :status => 'Completed'}.to_yaml
	@last_registration.save!

	control = page.all("[value^=\"#{amount}\"]")
	
	@last_payment_amount = amount

	if control.length > 0
		control.first.trigger('click')
	else
		fill_in(locate('amount'), :with => amount)
		click_link_or_button(locate('payment'))
	end
end

Then(/^(I )?(don't )?have enough funds$/) do | a, status |
	if status.blank?
		info = YAML.load(@last_registration.payment_info)
		info[:status] = 'Completed'
		@last_registration.payment_info = info.to_yaml
		@last_registration.save!
	end
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

Then(/^(I )?(should )?(not )?see (.+)$/) do | a, b, no, item |
	if /(the )?Bike!Bike! logo$/ =~ item
		if no.present?
			expect(page).not_to have_selector('.bb-icon-logo')
		else
			expect(page).to have_selector('.bb-icon-logo')
		end
	elsif /(the|a)?\s?(.+) menu item$/ =~ item
		within('#main-nav') {
			if no.present?
				expect(page).not_to have_link Regexp.last_match(2)
			else
				expect(page).to have_link Regexp.last_match(2)
			end
		}
	elsif /(the|a)?\s?(.+) image$/ =~ item
		if no.present?
			expect(page).not_to have_selector("##{Regexp.last_match(2)} img")
		else
			expect(page).to have_selector("##{Regexp.last_match(2)} img")
		end
	elsif /(the|a)?\s?(.+) link$/ =~ item
		if no.present?
			expect(page).not_to have_link Regexp.last_match(2)
		else
			expect(page).to have_link Regexp.last_match(2)
		end
	else
		if no.present?
			expect(page).not_to have_text item
		else
			expect(page).to have_text item
		end
	end
end

Then(/^(I )?wait (\d+) seconds$/) do | a, time |
	sleep time.to_i
end

##  =======   Forms   =======  ##

Then(/^(I )?click (on )?(the first )?(.+?)( button| link| which is hidden)?$/) do | a, b, first, item, type |
	item = item.gsub(/^\s*(a|the)\s*(.*)$/, '\2')
	if type && type.strip == 'button'
		click_button(item)
	elsif type && type.strip == 'link'
		#print page.html
		click_link(item)
	elsif type && type =~ /hidden/
		find('[id$="' + item.gsub(/\s+/, '_') + '"]', :visible => false).click
	else
		if first.present?
			page.first(:link, item).trigger('click')
		else
			page.find_link(item).trigger('click')
		end
	end
end

Then(/^(I )?press (.+)$/) do | a, item |
	click_link_or_button(page.find('button[value$="' + item.gsub(/\s+/, '_') + '"]').text)#locate(item))
end

Then(/^(I )?(un)?check (.+)$/) do | a, state, item |
	if state == 'un'
		uncheck(locate(item))
	else
		check(locate(item))
	end
end

#      (a ) (b                 ) (c        ) (value)(d                       ) (group)
Then(/^(I )?(select|choose|want) (an? |the )?(.+?)( as my| as the| as an?| for)? (.+)$/) do | a, b, c, value, d, group |
	if (control = page.all("[name=\"#{group.pluralize}[#{value}]\"]".gsub(/^\s+$/, '_'))).length > 0
		method = check(control.first[:id])
	elsif (control = page.all("[name=\"#{group}\"][value=\"#{value}\"]".gsub(/^\s+$/, '_'))).length > 0
		control.first.trigger('click')
	else
		raise "Could not find control to select"
	end

end

Then(/^(I )?fill in (.+?) with (.+)$/) do | a, field, value |
	field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
	fill_in(locate(field), :with => value)

	if /email/ =~ field && !(/organization/ =~ field)
		@last_email_entered = value
	end
end

Then(/^(I )?enter (.+?) (as my |as the |in the|as an? )(.+)$/) do | a, value, b, field |
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

Then(/^(I )?show the (page|url)$/) do | a, item |
	if item == 'url'
		print current_url
	else
		print page.html
	end
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

Then (/^th(e|at) email should contain (.+)$/) do |a, value|
	@last_email = ActionMailer::Base.deliveries.last

	if @last_email.parts && @last_email.parts.first
		@last_email.parts.first.body.raw_source.should include(value)
		@last_email.parts.last.body.raw_source.should include(value)
	else
		@last_email.body.raw_source.should include(value)
	end
end

Then (/^in th(e|at) email I should see (.+)$/) do |a, value|
	@last_email = ActionMailer::Base.deliveries.last

	if /(an?|the|my) (.+) link/ =~ value
		value = path_to Regexp.last_match(2)
	end

	if @last_email.parts
		@last_email.parts.first.body.raw_source.should include(value)
		@last_email.parts.last.body.raw_source.should include(value)
	else
		@last_email.body.raw_source.should include(value)
	end
end

Then(/^(I )?confirm my account$/) do | a |
	@my_account = User.find_by(:email => @last_email_entered)
	@confirmation = EmailConfirmation.where(["user_id = ?", @my_account.id]).order("created_at DESC").first
	visit "/confirm/#{@confirmation.token}"
end

Then (/^I should (not )?be registered for the conference$/) do |state|
	@my_account = User.find_by(:email => @last_email_entered)
	@last_registration = ConferenceRegistration.find_by(:user_id => @my_account.id, :conference_id => @last_conference.id)
	if state && state.strip == 'not'
		@last_registration.should be_nil
	else
		@last_registration.should_not be_nil
	end
end

Given (/^(I )?am logged in as (.+)$/) do |a, email|
	#include Sorcery::TestHelpers::Rails
	@my_account = User.create(:email => email)
	EmailConfirmation.create(:token => 'test', :user_id => @my_account.id)
	visit "/confirm/test"
	fill_in(locate('email'), :with => email)
	click_link_or_button(page.find('button[type="submit"]').text)
end

Given (/^My name is (.+)$/) do |name|
	@my_account.firstname = name
	@my_account.save
end

Given (/^(I )?am registered for the conference$/) do |a|
	@last_registration = ConferenceRegistration.create(
		:user_id        => @my_account.id,
		:conference_id  => @last_conference.id,
		:is_attending   => true,
		:is_confirmed   => true,
		:is_participant => true,
		:user_id        => @my_account.id,
		:city           => 'Somewhere',
		:arrival        => '2015-09-28 00:00:00',
		:departure      => '2015-09-28 00:00:00',
		:housing        => 'house',
		:bike           => 'medium',
		:other          => '',
		:allergies      => '',
		:languages      => '["en"]',
		:food           => 'meat'
	)
end

Given (/^(I )?have paid( \$?\d+|\$?\d+\.\d+)? for registration$/) do |a, amount|
	@last_registration.registration_fees_paid = amount ? amount.to_f : 50.0
	@last_registration.save
end

Given (/^(I )?am a conference host$/) do |a|
	org = @last_conference.organizations.first
	org.users ||= Array.new
	org.users << @my_account
	org.save
end

Then (/^(I )?save (my |the )workshop$/) do |a, b|
	title = find('[name=title]').value
	click_button('save')
	@last_workshop = Workshop.order('created_at DESC').first
end

Then (/^(I )?(view|edit|delete) (my |the )workshop$/) do |a, action, b|
	if action == 'view'
		visit "/conferences/#{@last_conference.slug}/workshops/#{@last_workshop.id}"
	else
		visit "/conferences/#{@last_conference.slug}/workshops/#{@last_workshop.id}/#{action}"
	end
end

Then (/^my registration (should( not)? be|is( not)?) (confirmed|completed?|paid)$/) do |state, x, y, field|
	ConferenceRegistration.find_by!(:email => @last_email_entered).
		send(field == 'confirmed' ? 'is_confirmed' : (field == 'paid' ? 'registration_fees_paid' : field)).
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
