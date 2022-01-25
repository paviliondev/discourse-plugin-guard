# frozen_string_literal: true

class PluginGuard::RegistrationSerializer < ApplicationSerializer
  attributes :status,
             :plugins,
             :updated_at,
             :server_url,
             :site_key

  def status
    object.active? ? 'registered' : 'unregistered'
  end

  def server_url
    PluginGuard.server_url
  end

  def site_key
    object.authorization.site_key?
  end
end
