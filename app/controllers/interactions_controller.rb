class InteractionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create] # Or handle CSRF via headers

  def create
    post_id = params[:post_id]
    interaction_type = params[:interaction_type]

    if post_id.blank? || interaction_type.blank?
      return render json: { error: "Missing parameters" }, status: :unprocessable_entity
    end

    interaction = UserInteraction.create!(
      user: current_user,
      post_id: post_id,
      interaction_type: interaction_type
    )

    render json: { success: true, id: interaction.id }
  rescue => e
    render json: { error: e.message }, status: :unprocessable_entity
  end
end
