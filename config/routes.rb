# frozen_string_literal: true

Discourse::Application.routes.append do
  get '/admin/plugins/plugin-guard/authorize' => 'plugin_guard/authorization#authorize'
  get '/admin/plugins/plugin-guard/authorize/callback' => 'plugin_guard/authorization#callback'
  get '/admin/plugins/plugin-guard/registration' => 'plugin_guard/registration#index', constraints: AdminConstraint.new
  delete '/admin/plugins/plugin-guard/registration' => 'plugin_guard/registration#destroy', constraints: AdminConstraint.new
end
