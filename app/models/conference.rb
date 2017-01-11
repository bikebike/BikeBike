class Conference < ActiveRecord::Base
  translates :info, :title, :payment_message

  mount_uploader :cover, CoverUploader
  mount_uploader :poster, PosterUploader

  belongs_to :conference_type
  belongs_to :city

  has_many :conference_host_organizations, dependent: :destroy
  has_many :organizations, through: :conference_host_organizations
  has_many :conference_administrators, dependent: :destroy
  has_many :administrators, through: :conference_administrators, source: :user
  has_many :event_locations
  
  has_many :workshops

  accepts_nested_attributes_for :conference_host_organizations, reject_if: proc {|u| u[:organization_id].blank?}, allow_destroy: true

  before_create :make_slug, :make_title

  def to_param
    slug
  end

  def host_organization?(org)
    return false unless org.present?
    org_id = org.is_a?(Organization) ? org.id : org

    organizations.each do |o|
      return true if o.id = org_id
    end

    return false
  end

  def host?(user)
    if user.present?
      return true if user.administrator?
      
      conference_administrators.each do |u|
        return true if user.id == u.id
      end
      
      organizations.each do |o|
        return true if o.host?(user)
      end
    end
    return false
  end

  def url(action = :show)
    path(action)
  end

  def path(action = :show)
    action = action.to_sym
    '/conferences/' + conference_type.slug + '/' + slug + (action == :show ? '' : '/' + action.to_s)
  end

  def location
    return nil unless organizations.present?
    organizations.first.location
  end

  def registered?(user)
    registration = ConferenceRegistration.find_by(:user_id => user.id, :conference_id => id)
    return registration ? registration.is_attending : false
  end

  def registration_exists?(user)
    ConferenceRegistration.find_by(:user_id => user.id, :conference_id => id).present?
  end

  def registration_open
    registration_status == :open
  end

  def can_register?
    registration_status == :open || registration_status == :pre
  end

  def registration_status
    s = read_attribute(:registration_status)
    s.present? ? s.to_sym : nil
  end

  def registration_status=(new_registration_status)
    write_attribute :registration_status, new_registration_status.to_s
  end

  def make_slug(reset = false)
    if reset
      self.slug = nil
    end

    self.slug ||= Conference.generate_slug(
        conferencetype || :annual,
        conference_year,
        city_name.gsub(/\s/, '')
      )
  end

  def make_title(reset = false)
    if reset
      self.title = nil
    end

    self.title ||= Conference.generate_title(
        conferencetype || :annual,
        conference_year,
        city_name.gsub(/\s/, '')
      )
  end

  def city_name
    return city.city if city.present?
    return location.present? ? location.city : nil
  end

  def conference_year
    self.year || (end_date.present? ? end_date.year : nil)
  end

  def over?
    return false unless end_date.present?
    return end_date < DateTime.now
  end

  def self.default_payment_amounts
    [25, 50, 100]
  end

  def self.conference_types
    {
      annual: { slug: '%{city}%{year}',   title: 'Bike!Bike! %{year}'},
      n:      { slug: 'North%{year}',     title: 'Bike!Bike! North %{year}'},
      s:      { slug: 'South%{year}',     title: 'Bike!Bike! South %{year}'},
      e:      { slug: 'East%{year}',      title: 'Bike!Bike! East %{year}'},
      w:      { slug: 'West%{year}',      title: 'Bike!Bike! West %{year}'},
      ne:     { slug: 'Northeast%{year}', title: 'Bike!Bike! Northeast %{year}'},
      nw:     { slug: 'Northwest%{year}', title: 'Bike!Bike! Northwest %{year}'},
      se:     { slug: 'Southeast%{year}', title: 'Bike!Bike! Southeast %{year}'},
      sw:     { slug: 'Southwest%{year}', title: 'Bike!Bike! Southwest %{year}'}
    }
  end

  def self.generate_slug(type, year, city)
    Conference.conference_types[(type || :annual).to_sym][:slug].gsub('%{city}', city).gsub('%{year}', year.to_s)
  end

  def self.generate_title(type, year, city)
    Conference.conference_types[(type || :annual).to_sym][:title].gsub('%{city}', city).gsub('%{year}', year.to_s)
  end

  def self.default_provider_conditions
    { 'distance' => { 'number' => 0, 'unit' => 'mi' }}
  end

end
