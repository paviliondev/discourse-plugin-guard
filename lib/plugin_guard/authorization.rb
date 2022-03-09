# frozen_string_literal: true
class PluginGuard::Authorization

  attr_reader :client_id,
              :auth_at,
              :api_key,
              :user_key

  def initialize(attrs)
    @api_key = attrs[:key]
    @auth_at = attrs[:auth_at]
    @client_id = get_client_id || set_client_id
    @user_key = attrs[:user_key]
  end

  def active?
    @api_key.present?
  end

  def user_key?
    @user_key
  end

  def site_key?
    api_key && !user_key?
  end

  def generate_keys(user_id, request_id)
    rsa = OpenSSL::PKey::RSA.generate(2048)
    nonce = SecureRandom.hex(32)
    set_keys(request_id, user_id, rsa, nonce)

    OpenStruct.new(nonce: nonce, public_key: rsa.public_key)
  end

  def decrypt_payload(request_id, payload)
    keys = get_keys(request_id)

    return false unless keys.present? && keys.pem
    delete_keys(request_id)

    rsa = OpenSSL::PKey::RSA.new(keys.pem)
    decrypted_payload = rsa.private_decrypt(Base64.decode64(payload))

    return false unless decrypted_payload.present?

    begin
      data = JSON.parse(decrypted_payload).symbolize_keys
    rescue JSON::ParserError
      return false
    end

    return false unless data[:nonce] == keys.nonce
    data[:user_id] = keys.user_id

    data
  end

  def url(user_id, request_id)
    keys = generate_keys(user_id, request_id)
    params = {
      public_key: keys.public_key,
      nonce: keys.nonce,
      client_id: client_id,
      auth_redirect: "#{PluginGuard.client_url}/admin/plugins/plugin-guard/authorize/callback",
      application_name: SiteSetting.title,
      scopes: "discourse-plugin-manager:plugin_user"
    }

    uri = URI.parse("#{PluginGuard.server_url}/user-api-key/new")
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def handle_callback(request_id, payload)
    data = decrypt_payload(request_id, payload)
    return false unless data.is_a?(Hash) && data[:key] && data[:user_id]

    api_key = data[:key]
    user_id = data[:user_id]
    user = User.find(user_id)

    if user&.admin && self.class.set(api_key)
      true
    else
      false
    end
  end

  def self.get
    raw = PluginStore.get(PluginGuard::NAMESPACE, authorization_db_key) || {}
    new(raw.symbolize_keys)
  end

  def self.set(key)
    PluginStore.set(PluginGuard::NAMESPACE, authorization_db_key,
      key: key,
      user_key: true,
      auth_at: DateTime.now.iso8601(3)
    )
    get
  end

  def self.set_site_api_key(key, validate: true)
    return false if validate && !validate_site_api_key(key)

    PluginStore.set(PluginGuard::NAMESPACE, authorization_db_key,
      key: key,
      user_key: false,
      auth_at: nil
    )
  end

  def self.remove
    PluginStore.remove(PluginGuard::NAMESPACE, authorization_db_key)
  end

  def self.authorization_db_key
    "authorization"
  end

  def self.validate_site_api_key(key)
    begin
      response = Excon.get("#{PluginGuard.server_url}/plugin-manager/status/validate-key.json",
        headers: {
          "Api-Key" => key,
          "Api-Username" => "system",
          "Content-Type" => "application/json"
        },
      )
    rescue Excon::Error
      return false
    end

    return false unless response.status == 200

    begin
      data = JSON.parse(response.body).symbolize_keys
    rescue JSON::ParserError
      return false
    end

    data[:success] == "OK"
  end

  private

  def keys_db_key
    "keys"
  end

  def client_id_db_key
    "client_id"
  end

  def set_keys(request_id, user_id, rsa, nonce)
    PluginStore.set(PluginGuard::NAMESPACE, "#{keys_db_key}_#{request_id}",
      user_id: user_id,
      pem: rsa.export,
      nonce: nonce
    )
  end

  def get_keys(request_id)
    raw = PluginStore.get(PluginGuard::NAMESPACE, "#{keys_db_key}_#{request_id}")
    OpenStruct.new(
      user_id: raw && raw['user_id'],
      pem: raw && raw['pem'],
      nonce: raw && raw['nonce']
    )
  end

  def delete_keys(request_id)
    PluginStore.remove(PluginGuard::NAMESPACE, "#{keys_db_key}_#{request_id}")
  end

  def get_client_id
    PluginStore.get(PluginGuard::NAMESPACE, client_id_db_key)
  end

  def set_client_id
    client_id = SecureRandom.hex(32)
    PluginStore.set(PluginGuard::NAMESPACE, client_id_db_key, client_id)
    client_id
  end
end
