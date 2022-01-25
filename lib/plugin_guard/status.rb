# frozen_string_literal: true

class ::PluginGuard::Status
  def self.handle_startup_errors
    startup_errors = PluginGuard::Store.all
    if startup_errors.present?
      registration = PluginGuard::Registration.get

      if registration.active?
        plugin_status_changes = []

        startup_errors.each do |name, data|
          plugin_status_changes.push(
            plugin: name,
            status: 2, ## incompatible
            message: data[:message],
            backtrace: data[:backtrace]
          )
          registration.plugins.include?(plugin_name)
        end

        update(plugin_status_changes)
      end

      PluginGuard::Store.clear
    end
  end

  def self.update(plugin_status_changes)
    registration = ::PluginGuard::Registration.get
    return false unless registration.active?

    user_key = registration.authorization.user_key?
    header_key = user_key ? "User-Api-Key" : "Api-Key"
    url = "#{PluginGuard.server_url}/status"

    response = Excon.post(url,
      headers: {
        "#{header_key}" => registration.api_key
      },
      body: {
        domain: PluginGuard.client_domain,
        plugins: plugin_status_changes
      }
    )

    return false unless response.status == 200

    begin
      data = JSON.parse(response.body).deep_symbolize_keys
    rescue JSON::ParserError
      return false
    end

    data[:success] == "OK"
  end
end
