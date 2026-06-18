class AiFeaturesController < ApplicationController
  before_action :authenticate_user!

  def generate_caption
    image = params[:image]
    service = AiCaptionGeneratorService.new(image)
    result = service.generate
    
    if result[:success]
      render json: { caption: result[:caption] }
    else
      render json: { error: "Failed to generate caption" }, status: :unprocessable_entity
    end
  end

  def generate_smart_replies
    conversation = current_user.conversations.find_by(id: params[:conversation_id])
    
    if conversation.nil?
      return render json: { error: "Conversation not found" }, status: :not_found
    end

    # Get the last message not sent by the current user
    last_message = conversation.messages.where.not(user_id: current_user.id).where(deleted: false).order(created_at: :desc).first

    if last_message.nil? || last_message.body.blank?
      return render json: { replies: ["Hi!", "How are you?", "Hey there!"] } # Fallback if no text message
    end

    service = AiSmartReplyService.new(last_message.body)
    result = service.generate

    if result[:success]
      render json: { replies: result[:replies] }
    else
      render json: { error: "Failed to generate replies" }, status: :unprocessable_entity
    end
  end
end
