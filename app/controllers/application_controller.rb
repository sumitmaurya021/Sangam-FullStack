class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  before_action :authenticate_user!
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Make current_user available to views via helper
  helper_method :current_user

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
