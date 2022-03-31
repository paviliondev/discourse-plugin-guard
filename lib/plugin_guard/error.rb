# frozen_string_literal: true

class ::PluginGuard::Error < StandardError
  attr_reader :error

  def initialize(error)
    @error = error
  end

  def self.handle(error, plugin_path = nil)
    plugin_path = extract_plugin_path(error) if !plugin_path

    unless plugin_path.present?
      STDERR.puts <<~TEXT
        ** THE PLUGIN GUARD HAS CAUGHT AN ERROR, BUT CAN'T IDENTIFY THE SOURCE. **
        One of your plugins has an error. The plugin guard caught it, but can't
        tell where it's from. This is all we know at the moment:
        #{map_stack_trace(error)}
      TEXT

      exit 1
    end

    guard = ::PluginGuard.new(plugin_path)

    if guard.present?
      guard.handle(message: error.message, backtrace: error.backtrace.join($/))
    else
      raise error
    end
  end

  def self.extract_plugin_path(error)
    plugin_path = ""
    locations = []

    if error.backtrace_locations.present?
      locations = error.backtrace_locations.map do |location|
        location.respond_to?(:absolute_path) ? location.absolute_path : nil
      end.compact
    end

    if locations.blank?
      locations = error.backtrace.map { |trace| trace[/.*\//] }.compact
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

  def self.map_stack_trace(error)
    error.backtrace.each_with_index.inject([]) do |messages, (line, index)|
      if index == 0
        messages << "#{line}: #{error} (#{error.class})"
      else
        messages << "\t#{index}: from #{line}"
      end
    end.reverse.join("\n")
  end
end
