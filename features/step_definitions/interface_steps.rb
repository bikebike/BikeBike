Given(/^I am on the (.+) page$/) do |page_name|
  visit path_to(page_name)
end

Then(/^I can read about the current bikebike$/) do
  within('#conference-name') { expect(page).to have_text 'Bike!Bike!' }
  within('#conference-location') { expect(page).to have_text 'Columbus, Ohio' }
  within('#conference-date') { expect(page).to have_text 'August 30 - September 1' }
end

Then(/^I can register for the conference$/) do
  expect(page).to have_link 'Register'
end
