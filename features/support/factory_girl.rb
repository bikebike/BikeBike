FactoryGirl.define do
  factory :upcoming_conference, class: :Conference do
    info            Forgery::LoremIpsum.paragraphs(2, sentences: 6, html: true, random: true)
    start_date      Date.new(2025, 9, 1)
    end_date        Date.new(2025, 9, 4)
    conferencetype  :annual
    year            2025
    paypal_username 'joe'
    locale          'en'
    is_public       true
    is_featured     true

    factory :upcoming_regional_conference, class: :Conference do
      start_date      Date.new(2025, 2, 14)
      end_date        Date.new(2025, 2, 16)
      conferencetype  :nw
    end

    factory :past_conference, class: :Conference do
      start_date      Date.new(2013, 10, 3)
      end_date        Date.new(2013, 10, 6)
      year            2013
      is_featured     false
    end
  end

  factory :registration, class: :ConferenceRegistration do
    conference_id          nil
    user_id                nil
    is_attending           'y'
    registration_fees_paid [25, 50, 100, Random.rand(10...150)].sample
    arrival                nil
    departure              nil
    other                  Forgery::LoremIpsum.paragraph(random: true)
    allergies              Forgery::LoremIpsum.paragraph(random: true)
    steps_completed        [:policy, :contact_info, :questions, :hosting, :payment]
    can_provide_housing    false
    housing_data           {}
    city_id                2
  end

  factory :org, class: :Organization do
    name 'My Organization'
    info 'Curabitur non nulla sit amet nisl tempus convallis quis ac lectus.'
  end

  factory :user, class: :User do
    email     Forgery::Internet.email_address
    firstname Forgery::Name.full_name
  end

  factory :workshop, class: :Workshop do
    conference_id  nil
    languages      ['en'].to_json
  end
end

World(FactoryGirl::Syntax::Methods)

def create_user(options = {})
  options[:firstname] ||= Forgery(:name).full_name
  options[:email] ||= Forgery(:internet).email_address
  options[:languages] ||= ['en'].to_json
  options[:languages] = options[:languages].to_json if options[:languages].is_a?(Array)
  User.create(options)
end

def create_workshop(title, user = TestState.my_account)
  workshop = FactoryGirl.build(:workshop)
  workshop.conference_id = TestState.last_conference.id
  workshop.title = title || Forgery::LoremIpsum.sentence(random: true).gsub(/\.$/, '').titlecase
  workshop.theme = TestState::Sample[:workshop].all_themes
  workshop.space = TestState::Sample[:workshop].all_spaces
  workshop.needs = [TestState::Sample[:workshop].all_needs].to_json
  workshop.info = Forgery::LoremIpsum.paragraphs(Random.rand(1..4), sentences: Random.rand(3..8), random: true)
  workshop.save!
  WorkshopFacilitator.create(user_id: user.id, workshop_id: workshop.id, role: :creator)
  TestState.last_workshop = workshop
  return workshop
end

def create_location(options)
  location = EventLocation.new(options)
  location.conference_id = TestState.last_conference.id
  location.save!
  return location
end

def create_registration(user = TestState.my_account)
  registration = FactoryGirl.build(:registration)
  registration.conference_id = TestState.last_conference.id
  registration.user_id = user.id
  registration.arrival = TestState.last_conference.start_date
  registration.departure = TestState.last_conference.end_date
  registration.housing = TestState::Sample[:conference_registration].all_housing_options
  registration.bike = TestState::Sample[:conference_registration].all_bike_options
  registration.food = TestState::Sample[:conference_registration].all_food_options
  registration.save!

  if user == TestState.my_account
    TestState.my_registration = registration
  else
    TestState.last_registration = registration
  end
  
  return registration
end

def create_org(name = nil, location = nil)
  org = FactoryGirl.create(:org)
  found_location = nil
  if location.present?
    cache_file = File.join(File.dirname(__FILE__), 'location_cache.yml')
    cache = {}
    if File.exists?(cache_file)
      begin
        cache = YAML.load_file(cache_file)
      rescue
        # get rid of the cache if there's an error
      end
    end
    l = cache[location]
    if l.nil?
      l = Geocoder.search(location).first
      cache[location] = l
      File.open(cache_file, 'w') { |f| f.write cache.to_yaml }
    end
    begin
      found_location = Location.new(city: l.city, territory: l.province_code, country: l.country_code, latitude: l.latitude, longitude: l.longitude)
    rescue; end
    if found_location.nil?
      # let it though, we might be offline
      org.save!
      return org
    end
  end
  if name.present?
    org.name = name
    org.slug = org.generate_slug(name, found_location)
  end
  if found_location.present?
    org.locations << found_location
  end
  org.save!
  org
end
