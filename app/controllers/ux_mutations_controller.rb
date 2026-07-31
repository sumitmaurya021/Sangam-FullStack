class UxMutationsController < ApplicationController
  before_action :authenticate_user!, except: [:create]
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    page_route = params[:page_route] || request.referrer || "unknown"
    event_type = params[:event_type] || "field_hesitation"
    duration_ms = params[:duration_ms].to_i
    metadata = params[:metadata] || {}

    event = UxMutationEngineService.log_telemetry(
      user: current_user,
      page_route: page_route,
      event_type: event_type,
      duration_ms: duration_ms,
      metadata: metadata
    )

    render json: { success: true, event_id: event&.id }
  end

  def update
    preference = current_user.ux_mutation_preference || current_user.create_ux_mutation_preference!

    if preference.update(preference_params)
      redirect_back fallback_location: root_path, notice: "UX layout preference updated to '#{preference.layout_mode.humanize}'."
    else
      redirect_back fallback_location: root_path, alert: "Failed to update layout preference."
    end
  end

  def dashboard
    @is_admin = current_user.super_admin? || (current_user.respond_to?(:admin?) && current_user.admin?)

    if @is_admin
      @total_events = UxTelemetryEvent.count
      @recent_events = UxTelemetryEvent.recent.limit(20)
      @friction_events_count = UxTelemetryEvent.friction_events.count
      @mode_counts = UxMutationPreference.group(:layout_mode).count
      @top_friction_routes = UxTelemetryEvent.friction_events.group(:page_route).order('count_all DESC').limit(5).count
    else
      @total_events = current_user.ux_telemetry_events.count
      @recent_events = current_user.ux_telemetry_events.recent.limit(20)
      @friction_events_count = current_user.ux_telemetry_events.friction_events.count
      @mode_counts = { (current_user.ux_mutation_preference&.layout_mode || "standard") => 1 }
      @top_friction_routes = current_user.ux_telemetry_events.friction_events.group(:page_route).order('count_all DESC').limit(5).count
    end
  end


  private

  def preference_params
    params.require(:ux_mutation_preference).permit(:layout_mode, :auto_adapt)
  end
end
