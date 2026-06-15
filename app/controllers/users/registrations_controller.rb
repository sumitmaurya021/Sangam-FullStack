# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  def create
    super do |resource|
      if resource.persisted?
        NotificationMailer.welcome_email(resource).deliver_later
      end
    end
  end

  protected

  # If you have extra params to permit, append them to the sanitizer.
  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name])
  end

  # If you have extra params to permit, append them to the sanitizer.
  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [
      :name, :bio, :avatar, :cover_photo,
      :website_url, :birthday, :location, :dark_mode
    ])
  end

  # Allow profile fields and images to update without requiring the current
  # password. Password changes still go through Devise's default flow.
  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      params.delete(:password)
      params.delete(:password_confirmation)
      params.delete(:current_password)
      resource.update_without_password(params)
    else
      super
    end
  end
end
