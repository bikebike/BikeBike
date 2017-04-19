include Sorcery::TestHelpers::Rails

def locate(id)
  id = id.gsub(/\s+/, '_')
  e = page.all("[name=\"#{id}\"], [id=\"#{id}\"], [id^=\"#{id}--\"]")
  return e.first[:id]
end

def selector_for(id)
  prefixes = ['body.has-overlay .dlg.open ', 'body #primary-content ']
  selectors = ['[name="{id}"]', '[id="{id}"]', '[id^="{id}--"]']

  selector = []
  prefixes.each do | pre |
    selectors.each do | sel |
      selector << "#{pre}#{sel}".gsub(/\{id\}/, id)
    end
  end

  selector.join(',')
end

def get_language_code(language)
  languages = {
    'english' => 'en',
    'french' => 'fr',
    'spanish' => 'es',
    'german' => 'de'
  }
  languages[language.downcase]
end

def to_filename(filename)
  filename.gsub(/[^\w\s_-]+/, '')
    .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
    .gsub(/\s+/, '_')
end

def log_result(scenario)
  if Capybara.current_session.server.present?
    dir = "log/test-results/#{to_filename(scenario.feature.name)}"
    FileUtils::mkdir_p dir
    filename = "#{to_filename(scenario.name)}.html"
    File.write("#{dir}/#{filename}", capture_html)
  end
end

def capture_html(distance_from_root = 3)
  html = page.html
  host = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
  public_dir = "#{'../' * distance_from_root}public/"
  
  html.gsub(/(=\"|\(['"]?)(?:#{host})?\/(assets|uploads)/, "\\1#{public_dir}\\2")
end

def attempt_to(refresh_on_fail = false, &block)
  exception = nil
  begin
    retries ||= 0
    timeout ||= 0
    timeout += 1
    yield
  rescue Exception => e
    exception ||= e
    raise exception unless (retries += 1) <= 4
    visit TestState.last_page if TestState.last_page && refresh_on_fail
    sleep(timeout * timeout)
    retry
  end
end

def last_email_html
  if TestState.last_email.parts
    TestState.last_email.parts.last.body.raw_source
  else
    TestState.last_email.body.raw_source
  end
end

def find_in_last_email(selector, attribute = nil)
  html = last_email_html.gsub(/^.*?(<table .*<\/table>).*$/m, '\1').gsub(/\n/, ' ').gsub(/\'/, '\\\'')
  Nokogiri::HTML(html).at(selector).attr(attribute)
end

def emails_to(email_address, subject = nil)
  ActionMailer::Base.deliveries.select do |mail|
    mail.to.include?(email_address) &&
      (subject.nil? || mail.subject.downcase.include?(subject.downcase))
  end
end

def str_to_num(num)
  nums = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten']
  return nums.find_index(num) if nums.include?(num)

  case num
  when 'no', 'none'
    return 0
  when 'a', 'an'
    return 1
  when 'two', 'couple', 'a couple', 'couple of', 'a couple of'
    return 2
  end

  return num.to_i if num =~ /\d+/

  fail "Could not interpret '#{num}' as a number"
end

def compare(expected, actual, negate = false)
  case expected
  when /any|some/
    expectation = (be >= 1)
  else
    expectation = (be == str_to_num(expected))
  end
  expect(actual).send(negate ? :not_to : :to, expectation)
end

def email_address(user)
  case user
  when /(I|me)/
    TestState.last_email_entered || TestState.my_account.email
  when /^(?:the )?site administrator$/i
    'goodgodwin@hotmail.com'
  when /^'(.+)'$/
    get_user($1).email
  else
    user
  end
end

def get_locale(language)
  return ({
    spanish: :es,
    english: :en,
    french:  :fr,
    german:  :de,
    klingon: :tlh
  }[language.strip.downcase.to_sym] or fail "Unable to convert '#{language.trim}' into a locale")
end

def get_field(field)
  field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2').gsub(/\s/, '_')
  aliases = {'phone_number' => 'phone', 'email_address' => 'email'}
  return aliases[field] || field
end

def get_user(username)
  return create_user unless username.present?

  TestState::Users[username] = create_user({
      (username =~ /^[^\s]+@[^\s]+\.[^\s]+$/ ? :email : :firstname) => username
    }) unless TestState::Users[username].present?

  return TestState::Users[username]
end

def element_with_text(text, parent = page)
  smallest = nil
  parent.all('*', text: text).each do |node|
    smallest = node if smallest.nil? || smallest.native['outerHTML'].length > node.native['outerHTML'].length
  end
  return smallest
end

def parent_element(node)
  node.first(:xpath, './/..')
end

def headers_to_attributes(object)
  new_object = {}
  object.each do |key, value|
    new_object[key.underscore] = value
  end

  return new_object
end

def string_to_time(str)
  h, m = str.split(':')
  h = h.to_i
  m = m.to_i
  h += 12 if h < 6
  return h + (m > 0 ? 0.5 : 0)
end

def string_to_time_length(str)
  parts = str.match(/^(?:(\d+) hour)?\s*(?:(\d+) minutes)?$/)
  return (parts[1] || '0').to_i + ((parts[2] || '0').to_i > 0 ? 0.5 : 0)
end

def str_to_wday(str)
  return [:sun, :mon, :tue, :wed, :thu, :fri, :sat].index(str[0...3].downcase.to_sym)
end
