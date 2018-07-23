# frozen_string_literal: true

# The base controller for all ProActiveStorage controllers.
class ProActiveStorage::BaseController < ActionController::Base
  protect_from_forgery with: :exception

  before_action do
    ProActiveStorage::Current.host = request.base_url
  end
end
