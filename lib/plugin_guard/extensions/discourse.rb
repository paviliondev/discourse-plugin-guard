# frozen_string_literal: true

module PluginGuard::DiscourseExtension
  def activate_plugins!
    @plugins = []

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
        PluginGuard::Error.handle(error, plugin_instance.path)
        next
      end

      validator = PluginGuard::Validator.new(plugin_name)
      begin
        validator.validate_assets(plugin_instance)
      rescue ValidatorError => error
        PluginGuard::Error.handle(error, plugin_instance.path)
        next
      end

      @plugins << plugin_instance
    end

    ::DiscourseEvent.trigger(:after_plugin_activation)
  end
end
