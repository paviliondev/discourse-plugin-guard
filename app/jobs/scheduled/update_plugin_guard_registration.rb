# frozen_string_literal: true

class Jobs::UpdatePluginGuardRegistration < ::Jobs::Scheduled
  every 1.hour

  def execute(args = {})
    PluginGuard::Registration.update
  end
end
