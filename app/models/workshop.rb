class Workshop < ActiveRecord::Base
    translates :info, :title

    belongs_to :conference

    has_many :workshop_facilitators, :dependent => :destroy
    has_many :users, :through => :workshop_facilitators

    accepts_nested_attributes_for :workshop_facilitators, :reject_if => proc {|u| u[:user_id].blank?}, :allow_destroy => true

    before_create :make_slug

    def to_param
        slug
    end

    def role(user)
        return nil unless user
        workshop_facilitators.each do |u|
            if u.user_id == user.id
                return conference.registered?(user) ? u.role.to_sym : :unregistered
            end
        end
        return nil
    end

    def facilitator?(user)
        !!role(user)
    end

    def active_facilitators
        users = []
        workshop_facilitators.each do |u|
            users << User.find(u.user_id) if u.role.to_sym != :request
        end
        return users
    end

    def active_facilitator?(user)
        facilitator?(user) && !requested_collaborator?(user)
    end

    def public_facilitator?(user)
        return false if !active_facilitator?(user)
        return true if creator?(user)
        conference.registered?(user)
    end

    def creator?(user)
        role(user) == :creator
    end

    def collaborator?(user)
        role(user) == :collaborator
    end

    def requested_collaborator?(user)
        role(user) == :requested
    end

    def can_edit?(user)
        creator?(user) || collaborator?(user) || conference.host?(user)
    end

    def can_delete?(user)
        creator?(user) || conference.host?(user)
    end

    def can_show_interest?(user)
        !active_facilitator?(user)
    end

    def interested?(user)
        user.present? && !active_facilitator?(user) && WorkshopInterest.find_by(workshop_id: id, user_id: user.id)
    end

    def interested_count
        collaborators = []
        workshop_facilitators.each do |f|
            collaborators << f.user_id unless f.role.to_sym == :requested
        end
        interested = WorkshopInterest.where("workshop_id=#{id} AND user_id NOT IN (#{collaborators.join ','})")
        interested ? interested.size : 0
    end

    def can_translate?(user, lang)
        (user.can_translate? && lang.to_sym != locale.to_sym) || can_edit?(user)
    end

    def conference_day
        return nil unless start_time.present? && end_time.present?

        start_day = conference.start_date.change(hour: 0, minute: 0, second: 0)
        w_start_day = start_time.change(hour: 0, minute: 0, second: 0)
        return (((w_start_day - start_day) / 86400) + 1).to_i
    end

    def duration
        return nil unless start_time.present? && end_time.present?
        ((end_time - start_time) / 60).to_i
    end

    private
        def make_slug
            if !self.slug
                s = self.title.gsub(/[^a-z1-9]+/i, '-').chomp('-').gsub(/\-([A-Z])/, '\1')
                if Organization.find_by(:slug => s) && self.locations && self.locations[0]
                    s += '-' + self.locations[0].city
                    if Organization.find_by(:slug => s) && locations[0].territory
                        s += '-' + self.locations[0].territory
                    end
                    if Organization.find_by(:slug => s)
                        s += '-' + self.locations[0].country
                    end
                end
                attempt = 1
                ss = s
                while Organization.find_by(:slug => s)
                    attempt += 1
                    s = ss + '-' + attempt
                end
                self.slug = s
            end
        end
end
