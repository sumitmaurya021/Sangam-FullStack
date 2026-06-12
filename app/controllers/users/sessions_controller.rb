class Users::SessionsController < Devise::SessionsController
  # Override sign-in to intercept users with 2FA enabled.
  # Devise authenticates credentials normally, but we halt before establishing
  # the session and redirect to the OTP verification page instead.
  def create
    self.resource = warden.authenticate!(auth_options)

    if resource.otp_enabled?
      # Stash user id in session and redirect to OTP page — do NOT sign in yet
      warden.logout
      session[:pending_2fa_user_id] = resource.id
      redirect_to verify_two_factor_auth_path
    else
      # Normal login (no 2FA)
      set_flash_message!(:notice, :signed_in)
      sign_in(resource_name, resource)
      yield resource if block_given?
      respond_with resource, location: after_sign_in_path_for(resource)
    end
  end
end
