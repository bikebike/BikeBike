class Workshop < ActiveRecord::Base
    belongs_to :conference

    has_many :workshop_facilitators, :dependent => :destroy
    has_many :users, :through => :workshop_facilitators

    accepts_nested_attributes_for :workshop_facilitators, :reject_if => proc {|u| u[:user_id].blank?}, :allow_destroy => true

    before_create :make_slug

    def to_param
        slug
    end

    def role(user)
        workshop_facilitators.each do |u|
            return u.role.to_sym if u.user_id == user.id
        end
        return nil
    end

    def facilitator?(user)
        !!role(user)
    end

    def creator?(user)
        role(user) == :creator
    end

    def can_edit?(user)
        creator?(user)
    end

    def can_delete?(user)
        creator?(user)
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
