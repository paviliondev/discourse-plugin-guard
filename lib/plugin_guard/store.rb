# frozen_string_literal: true
class PluginGuard::Store
  @cache = {}

  def self.set(plugin_name, attrs)
    @cache[plugin_name] = attrs
  end

  def self.get(plugin_name)
    @cache[plugin_name]
  end

  def self.all
    @cache
  end

  def self.clear
    @cache = {}
  end

  def self.process
    if all.present?
      plugins = []

      all.each do |name, data|
        plugin = {
          plugin: name,
          directory: data[:directory],
          status: data[:status]
        }
        plugin[:message] = data[:message] if data[:message].present?
        plugin[:backtrace] = data[:backtrace] if data[:message].present?
        plugins.push(plugin)
      end

      status = PluginGuard::Status.new(plugins)
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
