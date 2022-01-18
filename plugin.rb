# frozen_string_literal: true
# name: discourse-plugin-guard
# about: Guards your Discourse against plugin issues
# version: 0.1.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-plugin-guard.git

register_asset "stylesheets/common/admin.scss"

if Rails.env.test?
  %w(
    ../lib/plugin_guard.rb
    ../lib/plugin_guard/extensions/discourse.rb
    ../lib/plugin_guard/extensions/plugin_instance.rb
  ).each do |path|
    load File.expand_path(path, __FILE__)
  end
  FileUtils.mv('../lib/plugin_initialization_guard.rb', '../../../lib/plugin_initialization_guard.rb', force: true)
end

after_initialize do
  %w(
    ../lib/plugin_guard/authorization.rb
    ../lib/plugin_guard/registration.rb
    ../lib/plugin_guard/status.rb
    ../lib/plugin_guard/store.rb
    ../app/controllers/plugin_guard/authorization_controller.rb
    ../app/controllers/plugin_guard/registration_controller.rb
    ../app/serializers/plugin_guard/registration_serializer.rb
    ../app/jobs/scheduled/update_plugin_guard_registration.rb
    ../config/routes.rb
  ).each do |path|
    load File.expand_path(path, __FILE__)
  end

  startup_errors = PluginGuard::Store.all
  if startup_errors.present?
    registration = PluginGuard::Registration.get

    if registration.active?
      registered_plugin_errors = startup_errors.select do |plugin_name, _|
        registration.plugins.include?(plugin_name)
      end

      PluginGuard::Status.update(registered_plugin_errors)
    end

    PluginGuard::Store.clear
  end

  class ::AdminPluginSerializer
    attributes :guarded

    def guarded
      registration &&
      registration.plugins.present? &&
      registration.plugins.include?(name)
    end

    protected

    def registration
      @registration ||= PluginGuard::Registration.get
    end
  end
end
