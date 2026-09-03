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
    @preference = current_user.ux_mutation_preference || current_user.create_ux_mutation_preference!(
      layout_mode: "standard",
      auto_adapt: true,
      friction_score: 0.0
    )

    if @is_admin
      @total_events = UxTelemetryEvent.count
      @recent_events = UxTelemetryEvent.recent.limit(25)
      @friction_events_count = UxTelemetryEvent.friction_events.count
      @mode_counts = UxMutationPreference.group(:layout_mode).count
      @top_friction_routes = UxTelemetryEvent.friction_events.group(:page_route).order('count_all DESC').limit(5).count
      @hesitations_count = UxTelemetryEvent.where(event_type: 'field_hesitation').count
      @abandonments_count = UxTelemetryEvent.where(event_type: 'form_abandonment').count
      @backtracks_count = UxTelemetryEvent.where(event_type: 'rapid_backtrack').count
    else
      @total_events = current_user.ux_telemetry_events.count
      @recent_events = current_user.ux_telemetry_events.recent.limit(25)
      @friction_events_count = current_user.ux_telemetry_events.friction_events.count
      @mode_counts = { (@preference.layout_mode || "standard") => 1 }
      @top_friction_routes = current_user.ux_telemetry_events.friction_events.group(:page_route).order('count_all DESC').limit(5).count
      @hesitations_count = current_user.ux_telemetry_events.where(event_type: 'field_hesitation').count
      @abandonments_count = current_user.ux_telemetry_events.where(event_type: 'form_abandonment').count
      @backtracks_count = current_user.ux_telemetry_events.where(event_type: 'rapid_backtrack').count
    end

    @friction_score = (@preference.friction_score || 0.0).round(2)
    @flow_health = [100 - (@friction_score * 10).round, 25].max
  end


  private

  def preference_params
    params.require(:ux_mutation_preference).permit(:layout_mode, :auto_adapt)
  end
end
