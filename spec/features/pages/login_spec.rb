require 'spec_helper'

describe 'Login' do

	it "has a title which is Bike!Bike!" do
		visit login_path
		expect(page).to have_link 'Bike!Bike!'
	end

	it "has a link to login" do
		visit login_path
		expect(page).to have_link 'Sign In', :href => '/login'
	end

	it "has a link to conferences" do
		visit login_path
		expect(find '.top-bar-section a[href$="/conferences"]').to have_text 'Conferences'
	end

	it "has a link to organizations" do
		visit login_path
		expect(find '.top-bar-section a[href$="/organizations"]').to have_text 'Organizations'
	end

	it "has a link to resources" do
		visit login_path
		expect(find '.top-bar-section a[href$="/resources"]').to have_text 'Resources'
	end

	it "has a login form" do
		visit login_path
		form = find 'form[action$="/user_sessions"]'
		expect(form).to have_button 'Sign In'
		expect(form).to have_field 'email_'
		expect(form).to have_field 'password'
		expect(form).to have_link 'facebook'
	end

	it "has a register form" do
		visit login_path
		form = find 'form[action$="/users"]'
		expect(form).to have_button 'register'
		expect(form).to have_field 'user_username'
		expect(form).to have_field 'user_email'
		expect(form).to have_field 'user_password'
		expect(form).to have_field 'user_password_confirmation'
	end

	it "allows you to register" do
		visit login_path
		fill_in "user_username", :with => "John"
		fill_in "user_email", :with => "johnsemail@example.com"
		fill_in "user_password", :with => "johnspassword"
		fill_in "user_password_confirmation", :with => "johnspassword"
		click_button "register"
	end

	describe "can actually happen" do

		let(:user) { FactoryGirl.create(:user) }

		it "allows you to login" do
			visit login_path
			form = find 'form[action$="/user_sessions"]'
			form.find("#email_").set(user.email)
			form.find("#password").set('secret')
			click_button "Sign_In"
		end

	end

end
