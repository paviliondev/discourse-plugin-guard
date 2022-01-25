# frozen_string_literal: true

class ::AdminPluginSerializer
  attributes :guarded

  def guarded
    registration &&
    registration.plugins.present? &&
    registration.plugins.include?(name)
  end

  protected

  def registration
    @registration ||= PluginGuard::Registration.get
  end
end
