require 'forgery'

Then /^(?:I )?(?:should )?(not )?see (?:the |an? )?'(.+)' link$/i do |no, item|
  attempt_to do
    if no.present?
      expect(page).not_to have_link item
    else
      TestState.it = first('a', text: item)
    end
  end
end

Then /^(?:I )?(?:should )?(?:still )?(not )?see '(.+)'$/i do |negate, item|
  attempt_to do
    expect(page).send(negate ? :not_to : :to, have_text(item))
  end
end

Then /^(?:I )?(?:should )?(?:still )?(not )?see (?:my |the )([^']+)$/i do |negate, item|
  attempt_to do
    expect(page).send(negate ? :not_to : :to, have_text(TestState::Values[get_field(item)]))
  end
end

Then /^(?:I )?click (?:on )?(?:the )?(a )?'(.+?)'( button| link)?(?: beside '(.+?)')?(?: again)?$/i do |first, item, type, beside|
  attempt_to do
    begin
      root_item = beside.present? ? element_with_text(/#{Regexp.escape(beside)}.*?#{Regexp.escape(item)}/) : page
      if type.present?
        type.strip!
        selector = {button: 'button, a.button', link: 'a'}[type.to_sym]
        element = root_item.first(selector, text: item) || root_item.first(selector, text: item, visible: false) || root_item.find(selector, text: item)
      else
        element = element_with_text(item, root_item)
      end
      element.click
    rescue Exception => e
      puts text
      raise e
    end
    sleep(1) # let any aimations or page loads to complete
  end
end

Then /^(?:I )?press (.+)$/i do |item|
  attempt_to do
    text = (item =~  /'(.*)'/ ? $1 : page.find('button[value$="' + item.gsub(/\s+/, '_') + '"]').text)
    click_link_or_button(text)
    sleep(1) # let any aimations or page loads to complete
  end
end

Then /^(?:I )?(un)?check '(.+)'$/i do |uncheck, text|
  begin
    find('.check-box-field label', text: text).click
  rescue Exception => e
    # if we didn't find a label with the text, look for an 'Other' option
    begin
      find(".check-box-field input[placeholder*='#{text}']").click
    rescue
      # if we failed to find that too, raise the original exception
      raise e
    end
  end
end

Then /^(?:I )?(un)?check ([^']+)$/i do |uncheck, name|
  find("input[type=\"checkbox\"][name$=\"[#{name.gsub(/\s/, '_')}]\"]").click
end

Then /^(?:my )?'(.+)' should (not )?be checked$/i do |text, negate|
  label = find('.check-box-field label', text: text)
  find("##{label[:for]}", visible: false).send(negate ? :should_not : :should, be_checked)
end

Then /^(?:I )?(?:select|choose|want) (?:an? |the )?'(.+?)'$/i do |value|
  option = first('option', text: value)
  option.first(:xpath, './/..').set(option.value)
end

Then /^(?:I )?fill in (.+?) with '(.*)'$/i do |field, value|
  field = field.gsub(/^\s*(my|the)?\s*(.+)$/, '\2').gsub(/\s/, '_')
  find(selector_for(field)).set value

  if /email/ =~ field && !(/organization/ =~ field)
    TestState.last_email_entered = value
  end
end

Then /^(?:I )?enter (?:my |an? |some |the )?(.+?)(?: as '(.+)')?$/i do |field, value|
  field = get_field(field)

  sel = selector_for(field)
  element = first(sel, visible: true) || first(sel, visible: false)
  
  html = false
  if element.tag_name.to_s.downcase == 'div'
    element = element.first('[contenteditable]')
    html = true
  end

  unless value.present?
    value = case field
    when /email(_address)?/
      TestState.last_email_entered || Forgery(:internet).email_address
    when 'name'
      Forgery(field).full_name
    when 'city', 'country', 'phone', 'province', 'state' ,'street_address', 'address'
      aliases = {'address' => 'street_address'}
      Forgery('address').send((aliases[field] || field).to_sym)
    when 'subject', 'title'
      Forgery::LoremIpsum.sentence(random: true).gsub(/\.$/, '').titlecase
    when /(comment|reply)/
      Forgery::LoremIpsum.paragraphs(2, sentences: 6, random: true, html: html)
    when 'message'
      Forgery::LoremIpsum.paragraphs(2, sentences: 6, random: true, html: html)
    when 'info'
      Forgery::LoremIpsum.paragraphs(rand(1..4), sentences: rand(3..8), random: true, html: html)
    else
      fail "Unknown selector '#{field}'"
    end
  end

 (TestState::Values[field] = value)

  element.set value

  if /email/ =~ field && !(/organization/ =~ field)
    TestState.last_email_entered = value
  end
end

Then /^(?:my )?(.+)? should (not )?be set to (.+)$/i do |field, should, value|
  field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
  page.find('[id$="' + field.gsub(/\s+/, '_') + '"]').value.send(should.nil? ? 'should' : 'should_not', eq(value))
end

Then /^(?:I )?set (.+?) to (.+)$/i do |field, value|
  field = field.gsub(/^\s*(my|the)\s*(.+)$/, '\2')
  page.find('[id$="' + field.gsub(/\s+/, '_') + '"]', :visible => false).set value
end

Then /^(?:I )?wait for (.+?) to appear$/i do |field|
  count = 0
  element = nil
  while element.nil? && count < 120
    begin element = page.find('[id$="' + field.gsub(/\s+/, '_') + '"]'); rescue; end
    begin element ||= page.find('[id$="' + field.gsub(/\s+/, '_') + '"]', :visible => false); rescue; end
    sleep(1)
    count += 1
  end
end

Then /^(?:I )?select (.+?) from (.+)$/i do |value, field|
  select(value, :from => locate(field))
end

Then /^in a new session$/i do
  Capybara.reset_sessions!
end

Then /^(?:my |the )([A-Z][a-z]+ )?(workshop|conference|user|conference registration) (.+?) should (not )?be '(.+?)'$/i do |locale, type, attribute, negate, value|
  object = TestState.send("last_#{type.gsub(' ', '_')}")
  attribute = attribute.gsub(' ', '_').downcase
  actual_value = locale ? object.get_column_for_locale!(attribute, get_locale(locale)) : object.send(attribute)
  expect(actual_value).send(negate ? :not_to : :to, (be == value))
end
