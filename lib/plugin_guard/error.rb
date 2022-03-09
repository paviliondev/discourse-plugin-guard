# frozen_string_literal: true

class ::PluginGuard::Error < StandardError
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def self.handle(e)
    plugin_path = extract_plugin_path(e).to_s
    raise new(e) unless plugin_path.present?

    if guard = ::PluginGuard.new(plugin_path)
      guard.handle(message: e.message, backtrace: e.backtrace.join($/))
    else
      raise new(e)
    end
  end

  def self.extract_plugin_path(e)
    e.backtrace_locations.lazy.map do |location|
      path = Pathname.new(location.absolute_path).ascend
      next if path.blank?
      path.lazy.find { |path| path.parent.to_s == plugin_dir }
    end.next
  end

  def self.plugin_dir
    (::PluginGuard.root_dir + ::PluginGuard.compatible_dir).to_s
  end
end
