# frozen_string_literal: true

require_relative "plugin_guard.rb"
require_relative "plugin_guard/extensions/discourse.rb"
require_relative "plugin_guard/extensions/plugin_instance.rb"

module Plugin
  INIT_GUARD_CALLS_KEY ||= "plugin-initialization-guard-calls"

  def self.initialization_guard(&block)
    called_count = Discourse.redis.get(INIT_GUARD_CALLS_KEY).to_i

    if called_count === 0
      Discourse.singleton_class.prepend PluginGuard::DiscourseExtension
      Plugin::Instance.prepend PluginGuard::PluginInstanceExtension
    end

    begin
      block.call
    rescue StandardError, ScriptError => error
      PluginGuard::Error.handle(error)
    end

    # The initialization guard is currently called twice in application.rb, with
    # the second block sending notify_after_initialize to all plugins.
    if called_count > 0
      PluginGuard::Status.update!
      Discourse.redis.del(INIT_GUARD_CALLS_KEY)
    else
      Discourse.redis.incr(INIT_GUARD_CALLS_KEY)
    end
  end
end
