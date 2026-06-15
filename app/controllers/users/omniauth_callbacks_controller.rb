class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # GET /users/auth/google_oauth2/callback
  def google_oauth2
    handle_oauth('Google')
  end

  # GET /users/auth/github/callback
  def github
    handle_oauth('GitHub')
  end

  def failure
    redirect_to new_user_session_path,
                alert: 'Authentication failed. Please try again or use email/password.'
  end

  private

  # Shared logic for all providers
  def handle_oauth(provider_name)
    @user = User.from_omniauth(request.env['omniauth.auth'])

    if @user.persisted?
      # Send welcome email for brand-new OAuth users (no password yet)
      if @user.saved_change_to_id?
        NotificationMailer.welcome_email(@user).deliver_later rescue nil
      end
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: provider_name) if is_navigational_format?
    else
      # Could not save user — redirect back to registration with pre-filled data
      session["devise.#{provider_name.downcase}_data"] =
        request.env['omniauth.auth'].except(:extra).to_h
      redirect_to new_user_registration_url,
                  alert: @user.errors.full_messages.join(', ')
    end
  end
end
