Given /^(?:I )?(?:(?:am )?on |visit )(?:the |my )(.+) page$/i do |page_name|
  attempt_to do
    visit path_to(page_name)
  end
end

Given /^(?:(?:I )?am )?on an? (.+) error page$/i do |page_name|
  case page_name
  when '404', '500'
    path = "/error_#{page_name}"
  when 'locale not available'
    path = 'locale_not_available_error/tlh'
  else
    raise "Unknown error page #{page_name}"
  end

  attempt_to do
    visit path
  end
end

Then /^(?:I )?should be on (?:the |an? | my)?(.+) page$/i do |page_name|
  attempt_to do
    path = path_to(page_name)
    path = /(https?\/\/:[^\/]+)?#{Regexp.escape(path)}\/?(\?|#|$)/ unless path.is_a?(Regexp)
    current_url.should match path
  end
end

Given /^I am on the (.+) site$/i do |language|
  ApplicationController::set_host (get_language_code(language) + '.bikebike.org')
end

Given /^I am in (.+)$/i do |location|
  ApplicationController::set_location (location)
end

When /^I go to the (.+) page$/i do |page_name|
  visit path_to(page_name)
end

Given /^a location( named .+)? exists?$/i do |title|
  location = EventLocation.new
  location.conference_id = TestState.last_conference.id
  location.title = title ? title.gsub(/^\s*named\s*(.*?)\s*$/, '\1') : Forgery::LoremIpsum.sentence({:random => true}).gsub(/\.$/, '').titlecase
  location.save
  TestState.last_location = location
end

Then /^(?:I )?show the (page|url)$/i do |item|
  if item == 'url'
    print current_url
  else
    print page.html
  end
end

Then /^(?:I )?wait (\d+(?:\.\d+)?) seconds?$/i do |time|
  sleep time.to_i
end

Then /^take a screenshot?$/i do
  page.save_screenshot(File.expand_path('./test.png'), full: true)
end

When /^(?:I )?re(?:fresh|load) the page$/i do
  attempt_to do
    visit current_url
  end
end
