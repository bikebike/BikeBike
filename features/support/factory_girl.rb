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
  registration.data = {
    'payment_method' => 'none',
    'email_sent' => true,
    'city_id' => 11,
    'new_org' => {
      'id' => 8,
      'email' => 'example@bikebike.org',
      'mailing_address' => "120 Assomption Blvd\r\nEdmundston, New Brunswick\r\nCanada E3V 2X4",
      'name' => 'Bike Pulp',
      'address' => '120 Assomption Blvd'
    },
    'current_step' => 'review',
    'is_org_member' => true,
    'group_ride' => true
  }
  registration.housing_data = { 'other' => '', 'companion' => false }
  
  registration.city_id = City.search('Los Angeles').id unless City.exists?(registration.city_id)
  registration.data['city_id'] = City.search('Montreal').id unless City.exists?(registration.data['city_id'])

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
    found_location = Location.create(city_id: City.search(location).id)
    org.locations << found_location
  end
  if name.present?
    org.name = name
    org.slug = org.generate_slug(name, found_location)
  end
  org.save!
  org
end
