class MessagesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation

  def create
    @message = @conversation.messages.build(message_params)
    @message.user = current_user

    if @message.save
      render json: { success: true, message_id: @message.id }, status: :created
    else
      Rails.logger.error "Message save failed: #{@message.errors.full_messages}"
      render json: { success: false, errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @message = @conversation.messages.find(params[:id])

    if @message.user == current_user
      @message.soft_delete!  # broadcasts deletion inside model
      render json: { success: true }
    else
      render json: { error: "Not authorized" }, status: :forbidden
    end
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:conversation_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Conversation not found" }, status: :not_found
  end

  def message_params
    if request.content_type&.include?("application/json")
      params.require(:message).permit(:body, :message_type)
    else
      params.require(:message).permit(:body, :message_type, :attachment)
    end
  end
end
