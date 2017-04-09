require 'lingua_franca/form_helper'

module ApplicationHelper
  include PageHelper
  include RegistrationHelper
  include FormHelper
  include I18nHelper
  include WidgetsHelper
  include GeocoderHelper
  include TableHelper
  include AdminHelper

  def is_production?
    Rails.env == 'production' || Rails.env == 'preview'
  end

  def is_test?
    Rails.env == 'test'
  end

  def generate_confirmation(user, url, expiry = nil)
    ApplicationController::generate_confirmation(user, url, expiry)
  end
end
