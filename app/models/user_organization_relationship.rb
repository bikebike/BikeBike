class UserOrganizationRelationship < ActiveRecord::Base
  belongs_to :user
  belongs_to :organization

  Administrator = 'administrator'
  Member = 'member'
  
  DefaultRelationship = Member

  AllRelationships = [Administrator, Member]
end
