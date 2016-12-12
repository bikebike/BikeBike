class RenameConferenceType < ActiveRecord::Migration
  def change
    rename_column  :conferences, :type, :conferencetype
    
    Conference.all.each do |c|
      c.update_attribute :conferencetype, (c.conference_type == 5 ? 'regional' : 'annual')
    end
  end
end
