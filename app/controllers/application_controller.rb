class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Make current_user and current_ux_mode available to views via helper
  helper_method :current_user, :current_ux_mode

  def current_ux_mode
    return "standard" unless user_signed_in?
    @current_ux_mode ||= current_user.ux_mutation_preference&.layout_mode || "standard"
  end


  # Redirect to root with alert on record not found
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def not_found
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Page not found.' }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end
end
