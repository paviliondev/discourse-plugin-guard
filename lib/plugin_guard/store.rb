# frozen_string_literal: true
class PluginGuard::Store
  KEY ||= "plugin-guard-store"

  def self.get(key)
    Discourse.redis.get("#{KEY}:#{key}")
  end

  def self.set(key, attrs)
    Discourse.redis.set("#{KEY}:#{key}", attrs.to_json)
  end

  def self.clear
    Discourse.redis.scan_each(match: "#{KEY}:*").each { |key| Discourse.redis.del(key) }
  end

  def self.hash
    result = {}

    Discourse.redis.scan_each(match: "#{KEY}:*") do |key|
      value = Discourse.redis.get(key)
      next unless value.present?
      result[key.split("#{KEY}:").last] = JSON.parse(value).symbolize_keys
    end

    result
  end

  def self.database_ready?
    ActiveRecord::Base.connection
    ActiveRecord::Base.connection.data_source_exists? 'plugin_store_rows'
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    false
  end
end
