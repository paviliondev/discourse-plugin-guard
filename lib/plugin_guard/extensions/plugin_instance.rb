# frozen_string_literal: true

module PluginGuard::PluginInstanceExtension
  def notify_after_initialize
    color_schemes.each do |c|
      unless ColorScheme.where(name: c[:name]).exists?
        ColorScheme.create_from_base(name: c[:name], colors: c[:colors])
      end
    end

    initializers.each do |callback|
      begin
        callback.call(self)
      rescue StandardError, ScriptError => error
        PluginGuard::Error.handle(error)
        next
      end

      ## Report compatible status at the end of the plugin initialization cycle.
      PluginGuard::Store.set(name, status: PluginGuard::Status.status[:compatible])
    end
  end
end
