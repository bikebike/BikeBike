require 'spec_helper'

describe 'Organization Registration' do

	let(:user) { FactoryGirl.create(:user) }

	before(:each) do
		visit login_path
		form = find 'form[action$="/user_sessions"]'
		form.find("#email_").set(user.email)
		form.find("#password").set('secret')
		click_button "Sign_In"
		visit new_organization_path
	end

	it "works as expected" do
		fill_in 'organization_name', :with => 'Bike Kitchen'
		fill_in 'organization_slug', :with => 'bike-kitchen'
		fill_in 'organization_email_address', :with => 'bikekitchen@example.com'
	end
end
