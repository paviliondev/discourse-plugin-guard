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

      PluginGuard::Status.update(plugins)

      clear
    end
  end
end
