# frozen_string_literal: true
class PluginGuard::Store
  KEY = "plugin-guard-store"

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
      plugins[key.split("#{KEY}-").last] = JSON.parse(content).symbolize_keys
    end

    if plugins.present?
      statuses = []

      plugins.each do |name, data|
        status = {
          plugin: name,
          directory: data[:directory],
          status: data[:status]
        }
        status[:message] = data[:message] if data[:message].present?
        status[:backtrace] = data[:backtrace] if data[:message].present?
        statuses.push(status)
      end

      status = PluginGuard::Status.new(statuses)
      status.update

      if status.errors.any?
        status.errors.each do |error|
          Rails.logger.error "PluginGuard::Status.update failed. Errors: #{error.to_s}"
        end
      else
        Rails.logger.info "PluginGuard::Status.update succeeded. Reported #{plugins.map { |p| "#{p[:name]}: #{p[:status]}; " }}"
      end

      clear
    end
  end
end
