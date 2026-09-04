class UxMutationEngineService
  def initialize(user)
    @user = user
    @preference = user.ux_mutation_preference || user.create_ux_mutation_preference!(
      layout_mode: "standard",
      auto_adapt: true,
      friction_score: 0.0
    )
  end

  def evaluate_and_mutate!
    return @preference.layout_mode unless @preference.auto_adapt?

    # Calculate friction score based on telemetry events in the past 30 days
    recent_events = @user.ux_telemetry_events.where("created_at >= ?", 30.days.ago)
    
    abandonments = recent_events.where(event_type: "form_abandonment").count
    hesitations = recent_events.where(event_type: "field_hesitation").count
    backtracks = recent_events.where(event_type: "rapid_backtrack").count

    # Weighted friction calculation
    computed_score = (abandonments * 2.5) + (hesitations * 1.0) + (backtracks * 1.5)
    computed_score = computed_score.round(2)

    # Determine recommended layout mode
    target_mode = case
                  when computed_score >= 5.0
                    "minimalist" # High friction -> mutate to simplified UI
                  when recent_events.count > 50 && computed_score < 1.0
                    "power_density" # High velocity power user -> mutate to compact density
                  else
                    "standard"
                  end

    # Perform mutation if layout mode changes or score shifts
    if @preference.layout_mode != target_mode || @preference.friction_score != computed_score
      @preference.update!(
        layout_mode: target_mode,
        friction_score: computed_score
      )
    end

    target_mode
  end

  def self.log_telemetry(user:, page_route:, event_type:, duration_ms: 0, metadata: {})
    event = UxTelemetryEvent.create!(
      user: user,
      page_route: page_route,
      event_type: event_type,
      duration_ms: duration_ms,
      metadata: metadata
    )

    # Trigger evaluation asynchronously if associated with a user
    if user.present?
      new(user).evaluate_and_mutate!
    end

    event
  rescue StandardError => e
    Rails.logger.error("UxMutationEngineService log_telemetry error: #{e.message}")
    nil
  end
end
