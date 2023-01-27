# frozen_string_literal: true
# name: discourse-plugin-guard
# about: Guards your Discourse against plugin issues
# version: 0.1.2
# authors: Angus McLeod
# url: https://github.com/paviliondev/discourse-plugin-guard.git
# contact_emails: development@pavilion.tech

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

  FileUtils.mv('../lib/plugin.rb', '../../../lib/plugin.rb', force: true)
end

after_initialize do
  %w(
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
    api_key = SiteSetting.plugin_manager_api_key
    PluginGuard::Authorization.set_site_api_key(api_key)
    PluginGuard::Registration.update!
  end
end
