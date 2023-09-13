# frozen_string_literal: true

module PluginGuard::DiscourseExtension
  def activate_plugins!
    @plugins = []
    @plugins_by_name = {}

    Plugin::Instance.find_all("#{Rails.root}/plugins").each do |plugin_instance|
      version = plugin_instance.metadata.required_version || Discourse::VERSION::STRING
      plugin_name = plugin_instance.metadata.name

      unless Discourse.has_needed_version?(Discourse::VERSION::STRING, version)
        directory = File.dirname(plugin_instance.path)
        guard = PluginGuard.new(directory)
        message = "Could not activate #{plugin_name}, discourse does not meet required version (#{version})"
        guard.handle(message: message)
        next
      end

      begin
        plugin_instance.activate!
      rescue StandardError, ScriptError => error
        PluginGuard::Error.handle(error, File.dirname(plugin_instance.path))
        next
      end

      @plugins << plugin_instance
      @plugins_by_name[plugin_name] = plugin_instance

      # See further discourse/discourse/lib/discourse.rb
      dir_name = plugin_instance.path.split("/")[-2]
      if plugin_name != dir_name
        STDERR.puts "Plugin name is '#{plugin_name}', but plugin directory is named '#{dir_name}'"
        @plugins_by_name[dir_name] = plugin_instance
      end
    end

    ::DiscourseEvent.trigger(:after_plugin_activation)
  end
end
