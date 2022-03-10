# frozen_string_literal: true

class ::PluginGuard::Error < StandardError
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def self.handle(e)
    plugin_path = extract_plugin_path(e)
    raise new(e) unless plugin_path.present?

    if guard = ::PluginGuard.new(plugin_path)
      guard.handle(message: e.message, backtrace: e.backtrace.join($/))
    else
      raise new(e)
    end
  end

  def self.extract_plugin_path(e)
    plugin_path = ""
    locations = []

    if e.backtrace_locations.present?
      locations = e.backtrace_locations.map do |l|
        l.respond_to?(:absolute_path) ? l.absolute_path : nil
      end.compact
    end

    if locations.blank?
      locations = e.backtrace.map { |b| b[/.*\//] }.compact
    end

    return plugin_path unless locations.present?

    locations.each do |location|
      paths = Pathname.new(location).ascend

      if paths
        path = paths.find { |p| p.parent.to_s == plugin_dir }
        plugin_path = path if path
      end
    end

    plugin_path.to_s.chomp('/')
  end

  def self.plugin_dir
    (::PluginGuard.root_dir + ::PluginGuard.compatible_dir).to_s
  end
end
