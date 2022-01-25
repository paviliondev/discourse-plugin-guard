# frozen_string_literal: true
class PluginGuard::Registration
  include ActiveModel::Serialization

  attr_reader :plugins,
              :updated_at

  def initialize(attrs)
    @plugins = attrs[:plugins]
    @updated_at = attrs[:updated_at]
  end

  def active?
    authorization.active? && plugins.present? && (
      (updated_at && updated_at > 3.days.ago) || ## user registered
      authorization.site_key? ## site registered
    )
  end

  def authorization
    @authorization ||= PluginGuard::Authorization.get
  end

  def destroy
    self.class.remove
    PluginGuard::Authorization.remove
  end

  def self.registration_db_key
    "registration"
  end

  def self.set(attrs)
    raw = PluginStore.get(PluginGuard::NAMESPACE, registration_db_key) || {}
    attrs.each { |k, v| raw[k.to_s] = v }
    PluginStore.set(PluginGuard::NAMESPACE, registration_db_key, raw)
  end

  def self.get
    raw = PluginStore.get(PluginGuard::NAMESPACE, registration_db_key) || {}
    new(raw.symbolize_keys)
  end

  def self.remove
    PluginStore.remove(PluginGuard::NAMESPACE, registration_db_key)
  end

  def self.update
    auth = PluginGuard::Authorization.get

    if auth.active? && auth.user_key?
      url = "#{::PluginGuard.server_url}/plugin-manager/user/register"
      response = Excon.post(url,
        headers: {
          "User-Api-Key" => auth.api_key,
          "Content-Type" => "application/json"
        },
        body: {
          plugins: registrable_plugins,
          domain: PluginGuard.client_domain
        }.to_json
      )

      if response.status == 200
        begin
          data = JSON.parse(response.body).deep_symbolize_keys
        rescue JSON::ParserError
          return false
        end

        if data[:success] == "OK"
          set(updated_at: data[:updated_at], plugins: data[:plugins])
          return true
        end
      end
    end

    set(updated_at: nil)
    false
  end

  def self.registrable_plugins
    ::Discourse.unofficial_plugins.map(&:name)
  end
end
