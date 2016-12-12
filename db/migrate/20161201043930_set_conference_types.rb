class SetConferenceTypes < ActiveRecord::Migration
  def change
    types = {
      'Bike!Bike! 2013' => :annual,
      'Bike!Bike! Southeast 2014' => :se,
      'Bike!Bike! North 2014' => :n,
      'Ohio! Ohio!' => :ne,
      'Bike!Bike! 2014' => :annual,
      'Bike!Bike! 2015' => :annual,
      'Bike!Bike! 2016' => :annual
    }
    Conference.all.each do |c|
      c.conferencetype = types[c.title] || :annual
      c.year ||= c.end_date.year
      c.slug = nil
      c.make_slug
      c.save!
    end
  end
end
