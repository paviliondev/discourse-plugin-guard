# frozen_string_literal: true

class PluginGuard::RegistrationSerializer < ApplicationSerializer
  attributes :status,
             :plugins,
             :updated_at,
             :server_url

  def status
    object.active? ? 'registered' : 'unregistered'
  end

  def server_url
    "#{PluginGuard.protocol}://#{PluginGuard.server}"
  end
end
