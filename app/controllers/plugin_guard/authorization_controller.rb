# frozen_string_literal: true

class PluginGuard::AuthorizationController < ::Admin::AdminController
  skip_before_action :check_xhr, :preload_json, :verify_authenticity_token

  def authorize
    if authorization.site_key?
      render_json_error I18n.t("plugin_guard.error.plugin_manager_api_key"), status: :unprocessable_entity
    end

    request_id = SecureRandom.hex(32)
    cookies[:user_api_request_id] = request_id

    redirect_to authorization.url(current_user.id, request_id).to_s
  end

  def callback
    payload = params[:payload]
    request_id = cookies[:user_api_request_id]

    if authorization.handle_callback(request_id, payload)
      PluginGuard::Registration.update
    end

    redirect_to '/admin/plugins'
  end

  protected

  def authorization
    @authorization ||= ::PluginGuard::Authorization.get
  end
end
