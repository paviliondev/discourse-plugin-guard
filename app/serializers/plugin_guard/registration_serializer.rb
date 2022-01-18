# frozen_string_literal: true

class PluginGuard::RegistrationSerializer < ApplicationSerializer
  attributes :status,
             :plugins,
             :updated_at

  def status
    object.active? ? 'registered' : 'unregistered'
  end
end
