Then /^(?:I )?should not get an email$/i do
  ActionMailer::Base.deliveries.size.should eq 0
end

Then /^(.*) should get (.+) '(.+)' emails?$/i do |to, amount, subject|
  address = email_address(to)

  attempt_to do
    emails = emails_to(address, subject)

    unless emails.length == (str_to_num(amount))
      email_log = []
      ActionMailer::Base.deliveries.each do |mail|
        email_log << "\t#{mail.to.join(', ')}: #{mail.subject}"
      end
      total_emails = ActionMailer::Base.deliveries.length
      fail "Failed to find #{amount} email#{amount == 1 ? '' : 's'} to #{address} with #{subject} in the subject amoung #{total_emails} total email#{total_emails == 1 ? '' : 's'}:\n#{email_log.join("\n")}"
    end

    TestState.last_email = emails.first
  end
end

Then /^th(?:e|at) email should contain (.+)$/i do |value|
  TestState.last_email = ActionMailer::Base.deliveries.last

  if TestState.last_email.parts && TestState.last_email.parts.first
    TestState.last_email.parts.first.body.raw_source.should include(value)
    TestState.last_email.parts.last.body.raw_source.should include(value)
  else
    TestState.last_email.body.raw_source.should include(value)
  end
end

Then /^in th(?:e|at) email I should see (.+)$/i do |value|
  TestState.last_email = ActionMailer::Base.deliveries.last

  if /(an?|the|my) (.+) link/ =~ value
    value = path_to Regexp.last_match(2)
  end

  if TestState.last_email.parts
    TestState.last_email.parts.first.body.raw_source.should include(value)
    TestState.last_email.parts.last.body.raw_source.should include(value)
  else
    TestState.last_email.body.raw_source.should include(value)
  end
end

Then /^(?:I )?click (?:on )?(?:the )?(?:a )?'(.+?)' link in the email?$/i do | text |
  href = find_in_last_email("a:contains('#{text}')", :href)
  
  attempt_to do
    visit href
    sleep 1
  end
end
