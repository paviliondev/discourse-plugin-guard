# frozen_string_literal: true

class PluginGuard::RegistrationController < Admin::AdminController
  def show
    render_serialized(registration, PluginGuard::RegistrationSerializer)
  end

  def destroy
    if registration.destroy
      render json: success_json
    else
      render json: failed_json
    end
  end

  protected

  def registration
    @registration ||= ::PluginGuard::Registration.get
  end
end
