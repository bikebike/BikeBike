require 'i18n/backend/active_record'
I18n.backend = I18n::Backend::BikeBike.new
# I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Memoize)
# I18n::Backend::ActiveRecord.send(:include, I18n::Backend::Flatten)
