# frozen_string_literal: true

require_relative "plugin_guard.rb"
require_relative "plugin_guard/extensions/discourse.rb"
require_relative "plugin_guard/extensions/plugin_instance.rb"

@extensions_applied = false

def plugin_initialization_guard(&block)
  if !@extensions_applied
    Discourse.singleton_class.prepend PluginGuard::DiscourseExtension
    Plugin::Instance.prepend PluginGuard::PluginInstanceExtension
    @extensions_applied = true
  end

  begin
    block.call
  rescue StandardError, ScriptError => error
    PluginGuard::Error.handle(error)
  end
end
