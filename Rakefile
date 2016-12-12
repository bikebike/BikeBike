# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

BikeBike::Application.load_tasks

task regenerate_images: :environment do
  {
    conference: [ :cover, :poster ],
    organization: [ :logo, :avatar, :cover ]
  }.each do | model_class, attributes |
    Object.const_get(model_class.to_s.titlecase).all.each do | model |
      attributes.each do | attribute |
        uploader = model.send(attribute)
        if uploader.present?
          puts "Regenerating #{model_class}.#{attribute} = #{uploader.url}"
          uploader.recreate_versions!
        end
      end
    end
  end
end
