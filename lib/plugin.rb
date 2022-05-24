# frozen_string_literal: true

require_relative "plugin_guard.rb"
require_relative "plugin_guard/extensions/discourse.rb"
require_relative "plugin_guard/extensions/plugin_instance.rb"

module Plugin
  @@called_count = 0

  def self.initialization_guard(&block)

    if @@called_count === 0
      Discourse.singleton_class.prepend PluginGuard::DiscourseExtension
      Plugin::Instance.prepend PluginGuard::PluginInstanceExtension
      STDOUT.puts "PluginGuard initialized."
    end

    begin
      block.call
    rescue StandardError, ScriptError => error
      PluginGuard::Error.handle(error)
    end

    # The initialization guard is currently called twice in application.rb, with
    # the second block sending notify_after_initialize to all plugins.
    if @@called_count > 0
      PluginGuard::Status.update!
      @@called_count = 0
    else
      @@called_count = 1
    end
  end
end
