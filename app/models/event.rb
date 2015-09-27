class Event < ActiveRecord::Base
    belongs_to :conference

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

end
