# frozen_string_literal: true
class PluginGuard::Store
  KEY ||= "plugin-guard-store"

  def self.set(plugin_name, attrs)
    Discourse.redis.set("#{KEY}:#{plugin_name}", attrs.to_json)
  end

  def self.clear
    Discourse.redis.scan_each(match: "#{KEY}:*").each { |key| Discourse.redis.del(key) }
  end

  def self.process
    plugins = {}

    Discourse.redis.scan_each(match: "#{KEY}:*") do |key|
      content = Discourse.redis.get(key)
      next unless content.present?
      plugins[key.split("#{KEY}:").last] = JSON.parse(content).symbolize_keys
    end

    if plugins.present?
      plugin_statuses = []

      plugins.each do |name, data|
        plugin_status = {
          name: name,
          directory: data[:directory],
          status: data[:status]
        }
        plugin_status[:message] = data[:message] if data[:message].present?
        plugin_status[:backtrace] = data[:backtrace] if data[:message].present?
        plugin_statuses.push(plugin_status)
      end

      status = PluginGuard::Status.new(plugin_statuses)
      status.update

      if status.errors.any?
        Rails.logger.error "PluginGuard::Status.update failed. Errors: #{status.errors.full_messages.join("; ")}"
      else
        Rails.logger.info "PluginGuard::Status.update succeeded. Reported #{plugin_statuses.map { |ps| "#{ps[:name]}: #{ps[:status]}; " }}"
      end

      clear
    end
  end
end
