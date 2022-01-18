# frozen_string_literal: true

class ::PluginGuard::Status
  def self.update(errors)
    registration = ::PluginGuard::Registration.get

    if registration.active?
      url = "https://#{PluginGuard.server}/status"
      response = Excon.post(url,
        headers: {
          "User-Api-Key" => registration.api_key
        },
        body: errors
      )
      response.status == 200
    else
      false
    end
  end
end
