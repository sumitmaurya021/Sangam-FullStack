class GroupChatMessagesController < ApplicationController
  before_action :set_group_chat
  before_action :require_member!

  # POST /group_chats/:group_chat_id/messages
  def create
    @message = @group_chat.group_chat_messages.build(message_params)
    @message.user = current_user

    if @message.save
      render json: { success: true, message: @message.as_json_payload }, status: :created
    else
      render json: { errors: @message.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /group_chats/:group_chat_id/messages/:id
  def destroy
    message = @group_chat.group_chat_messages.find(params[:id])

    unless message.user == current_user || @group_chat.admin?(current_user)
      return render json: { error: 'Forbidden' }, status: :forbidden
    end

    message.soft_delete!
    render json: { success: true }
  end

  # GET /group_chats/:group_chat_id/messages  (load-more pagination)
  def index
    before_id = params[:before_id]
    messages  = @group_chat.group_chat_messages
                            .visible
                            .includes(:user, attachment_attachment: :blob)
                            .where(id: ...before_id.to_i)
                            .order(created_at: :desc)
                            .limit(30)
                            .reverse

    render json: {
      messages: messages.map(&:as_json_payload),
      has_more: @group_chat.group_chat_messages.visible.where(id: ...messages.first&.id).exists?
    }
  end

  private

  def set_group_chat
    @group_chat = GroupChat.find(params[:group_chat_id])
  end

  def require_member!
    unless @group_chat.member?(current_user)
      render json: { error: 'Not a member' }, status: :forbidden
    end
  end

  def message_params
    params.require(:group_chat_message).permit(:body, :message_type, :attachment)
  end
end
