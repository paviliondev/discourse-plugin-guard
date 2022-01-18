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
end
