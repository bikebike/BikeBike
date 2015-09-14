class WorkshopInterest < ActiveRecord::Base
	belongs_to :workshop
	has_one :user
end
