class ConversationChannel < ApplicationCable::Channel
  def subscribed
    conversation = Conversation.find_by(id: params[:conversation_id])

    if conversation && authorized?(conversation)
      stream_from "conversation_#{conversation.id}"
      # Mark messages as read when user opens the conversation
      conversation.mark_as_read_for!(current_user)
      # Broadcast read receipt to the other participant
      broadcast_read_receipt(conversation)
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def typing(data)
    conversation = Conversation.find_by(id: data['conversation_id'])
    return unless conversation && authorized?(conversation)

    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type:      'typing',
        user_id:   current_user.id,
        user_name: current_user.name,
        is_typing: data['is_typing']
      }
    )
  end

  def mark_read(data)
    conversation = Conversation.find_by(id: data['conversation_id'])
    return unless conversation && authorized?(conversation)

    conversation.mark_as_read_for!(current_user)
    broadcast_read_receipt(conversation)
  end

  def call_signal(data)
    conversation = Conversation.find_by(id: data['conversation_id'])
    return unless conversation && authorized?(conversation)

    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type:        'call_signal',
        signal_type: data['signal_type'],
        signal_data: data['signal_data'],
        caller_id:   current_user.id,
        caller_name: current_user.name,
        call_type:   data['call_type']
      }
    )
  end

  private

  def authorized?(conversation)
    conversation.sender_id == current_user.id ||
      conversation.recipient_id == current_user.id
  end

  def broadcast_read_receipt(conversation)
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        type:            'messages_read',
        reader_id:       current_user.id,
        conversation_id: conversation.id
      }
    )
  end
end
