class SettingsController < ApplicationController
  before_action :authenticate_user!

  # PATCH /settings/dark_mode
  def toggle_dark_mode
    current_user.update_column(:dark_mode, !current_user.dark_mode)
    render json: { dark_mode: current_user.dark_mode }
  end
end
