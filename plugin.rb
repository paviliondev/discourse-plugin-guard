# frozen_string_literal: true
# name: discourse-plugin-guard
# about: Guards your Discourse against plugin issues
# version: 0.1.1
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-plugin-guard.git

register_asset "stylesheets/common/admin.scss"
hide_plugin if self.respond_to?(:hide_plugin)

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
    ../extensions/admin_plugin_serializer.rb
    ../app/controllers/plugin_guard/authorization_controller.rb
    ../app/controllers/plugin_guard/registration_controller.rb
    ../app/serializers/plugin_guard/registration_serializer.rb
    ../app/jobs/scheduled/update_plugin_guard_registration.rb
    ../config/routes.rb
  ).each do |path|
    load File.expand_path(path, __FILE__)
  end

  if SiteSetting.plugin_manager_api_key.present?
    PluginGuard::Authorization.set_site_api_key(SiteSetting.plugin_manager_api_key)
    PluginGuard::Registration.update
  end

  PluginGuard::Store.process
end
