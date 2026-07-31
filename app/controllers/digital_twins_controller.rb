class DigitalTwinsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_digital_twin

  def show
    @logs = current_user.digital_twin_logs.recent.limit(20)
  end

  def update
    if @digital_twin.update(digital_twin_params)
      redirect_to digital_twin_path, notice: "Digital Twin configuration updated successfully."
    else
      @logs = current_user.digital_twin_logs.recent.limit(20)
      render :show, status: :unprocessable_entity
    end
  end

  def toggle
    @digital_twin.update(enabled: !@digital_twin.enabled)
    status_text = @digital_twin.enabled? ? "activated" : "deactivated"
    redirect_to digital_twin_path, notice: "Digital Twin proxy is now #{status_text}."
  end

  def test_run
    input_text = params[:test_input]
    trigger_source = params[:trigger_source] || "direct_message"

    if input_text.blank?
      return render json: { error: "Test input text is required" }, status: :unprocessable_entity
    end

    service = DigitalTwinExecutionService.new(
      user: current_user,
      trigger_source: trigger_source,
      input_text: input_text,
      sender_name: "Test Sandbox User"
    )

    result = service.execute
    render json: result
  end

  private

  def set_digital_twin
    @digital_twin = current_user.digital_twin || current_user.create_digital_twin!(
      enabled: false,
      persona_name: "#{current_user.display_name}'s Digital Twin",
      tone: "friendly_professional"
    )
  end

  def digital_twin_params
    params.require(:digital_twin).permit(
      :enabled, :mode, :persona_name, :tone, :custom_instructions,
      :auto_reply_dms, :auto_reply_marketplace, :auto_reply_group_chats,
      :min_marketplace_offer
    )
  end
end
