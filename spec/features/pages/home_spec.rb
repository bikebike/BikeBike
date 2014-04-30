require 'spec_helper'

describe 'Home' do
	it "has a title which is Bike!Bike!" do
		visit root_path
		expect(page).to have_link 'Bike!Bike!'
	end

	it "has a link to login" do
		visit root_path
		expect(page).to have_link 'Sign In', :href => '/login'
	end

	it "has a link to conferences" do
		visit root_path
		expect(find '.top-bar-section a[href$="/conferences"]').to have_text 'Conferences'
	end

	it "has a link to organizations" do
		visit root_path
		expect(find '.top-bar-section a[href$="/organizations"]').to have_text 'Organizations'
	end

	it "has a link to resources" do
		visit root_path
		expect(find '.top-bar-section a[href$="/resources"]').to have_text 'Resources'
	end

end
