require 'cucumber/rails'
require 'capybara/poltergeist'
require 'mocha/mini_test'
require 'fileutils'
require 'marmara'

ActionController::Base.allow_rescue = false

DatabaseCleaner.strategy = :truncation, { except: %w[cities city_cache] }

Capybara.register_driver :bb_poltergeist do |app|
  if ENV['CSS_TEST']
    Marmara.options = {
        ignore: [/paypal(?:objects)?/, 'assets.css'],
        rewrite: {
          from: /^.*\/(.*?)\/.*?\.css$/,
          to: '\1.css'
        },
        minimum: {
          declarations: 30
        }
      }
    Marmara.start_recording
  end

  opts = {
    timeout: 10,
    window_size: [1200, 800]
  }
  Capybara::Poltergeist::Driver.new(app, opts)
end

Before('@javascript') do
  ActiveRecord::Base.shared_connection = nil
  ActiveRecord::Base.descendants.each do |model|
    model.shared_connection = nil
  end
end

Before do
  TestState.reset!
  safari5 = "Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_8; de-at) AppleWebKit/533.21.1 (KHTML, like Gecko) Version/5.0.5 Safari/533.21.1"
  safari9 = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6) AppleWebKit/537.75.14 (KHTML, like Gecko) Version/9.3.2 Safari/537.75.14"
  chrome55 = "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
  ActionDispatch::Request.any_instance.stubs(:user_agent).returns(safari5)
  LinguaFranca.test_driver = page.driver
  host = "http://#{Capybara.current_session.server.host}:#{Capybara.current_session.server.port}"
  LinguaFranca.host = host
  Mail::TestMailer.deliveries.clear
end

After do |scenario|
  log_result scenario

  if LinguaFranca.recording?
    sleep 1
    LinguaFranca.screenshot_mail
  end

  if scenario.failed?
    if @exception
      puts @exception.to_s
      puts @exception.backtrace.join("\n")
    end
  end
end

After do
  DatabaseCleaner.clean
end

def step_wait_time(keyword)
  # give additional wait time to Given and When steps 

  if keyword == 'And' || keyword == 'But'
    keyword = @_last_keyword
  end
  
  @_last_keyword = keyword

  case keyword
  when 'Given'
    return 1 
  when 'When'
    return 3
  end

  return 0.5
end

AfterStep do |scenario, step|
  # capture used selectors to generate css coverage
  Marmara.record(step.source.last.keyword) if Marmara.recording?

  # take some extra time between steps if we're recording
  keyword = step.source.last.keyword.strip
  sleep(step_wait_time(keyword)) if LinguaFranca.recording?
end

Cucumber::Rails::Database.javascript_strategy = :transaction
Capybara.default_driver = :bb_poltergeist
Capybara.javascript_driver = :bb_poltergeist
Geocoder.configure(timeout: 60)

at_exit do
  Marmara.stop_recording if Marmara.recording?
end
