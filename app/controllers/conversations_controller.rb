class ConversationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_conversation, only: [:show, :destroy]

  def index
    @conversations = current_user.conversations
                                 .includes(:sender, :recipient, messages: :user)

    respond_to do |format|
      format.html
      format.json do
        render json: @conversations.map { |c|
          other = c.other_participant(current_user)
          last  = c.last_message
          {
            id: c.id,
            other_user: user_json(other),
            last_message: last ? message_json(last) : nil,
            unread_count: c.unread_count_for(current_user)
          }
        }
      end
    end
  end

  def show
    @other_user = @conversation.other_participant(current_user)
    @messages = @conversation.messages
                             .visible
                             .includes(:user, attachment_attachment: :blob)
                             .recent
                             .last(50)

    # Mark messages as read
    @conversation.mark_as_read_for!(current_user)

    respond_to do |format|
      format.html
      format.json { render json: conversation_json(@conversation, @messages) }
    end
  end

  def create
    recipient = User.find(params[:recipient_id])

    # Prevent conversation with self
    if recipient == current_user
      respond_to do |format|
        format.html { redirect_to root_path, alert: "Cannot start conversation with yourself" }
        format.json { render json: { error: "Cannot start conversation with yourself" }, status: :unprocessable_entity }
      end
      return
    end

    @conversation = Conversation.find_or_create_between(current_user, recipient)

    respond_to do |format|
      format.html { redirect_to conversation_path(@conversation) }
      format.json { render json: { conversation_id: @conversation.id }, status: :ok }
    end
  end

  def destroy
    @conversation.destroy
    redirect_to conversations_path, notice: "Conversation deleted."
  end

  # Load more messages (pagination)
  def messages
    @conversation = current_user.conversations.find(params[:id])
    before_id = params[:before_id]

    @messages = @conversation.messages
                             .visible
                             .includes(:user, attachment_attachment: :blob)
                             .where(id: ...before_id.to_i)
                             .order(created_at: :desc)
                             .limit(30)
                             .reverse

    render json: {
      messages: @messages.map { |m| message_json(m) },
      has_more: @conversation.messages.visible.where(id: ...@messages.first&.id).exists?
    }
  end

  private

  def set_conversation
    @conversation = current_user.conversations.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to conversations_path, alert: "Conversation not found."
  end

  def conversation_json(conversation, messages)
    other = conversation.other_participant(current_user)
    {
      id: conversation.id,
      other_user: user_json(other),
      messages: messages.map { |m| message_json(m) },
      unread_count: conversation.unread_count_for(current_user)
    }
  end

  def message_json(message)
    {
      id: message.id,
      body: message.deleted ? nil : message.body,
      message_type: message.message_type,
      user_id: message.user_id,
      sender_name: message.user.name,
      sender_avatar: message.user.avatar.attached? ? url_for(message.user.avatar) : nil,
      read_at: message.read_at&.iso8601,
      deleted: message.deleted,
      created_at: message.created_at.iso8601,
      attachment_url: (!message.deleted && message.attachment.attached?) ? url_for(message.attachment) : nil,
      attachment_filename: message.attachment_filename,
      attachment_content_type: message.attachment_content_type
    }
  end

  def user_json(user)
    {
      id: user.id,
      name: user.name,
      avatar: user.avatar.attached? ? url_for(user.avatar) : nil,
      online: user.online,
      last_seen_at: user.last_seen_at&.iso8601
    }
  end
end
