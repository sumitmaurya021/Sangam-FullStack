class GroupChatChannel < ApplicationCable::Channel
  def subscribed
    group_chat = GroupChat.find_by(id: params[:group_chat_id])

    if group_chat && group_chat.member?(current_user)
      stream_from "group_chat_#{group_chat.id}"
    else
      reject
    end
  end

  def unsubscribed
    stop_all_streams
  end

  def typing(data)
    group_chat = GroupChat.find_by(id: data['group_chat_id'])
    return unless group_chat&.member?(current_user)

    ActionCable.server.broadcast(
      "group_chat_#{group_chat.id}",
      {
        type:      'group_typing',
        user_id:   current_user.id,
        user_name: current_user.name,
        is_typing: data['is_typing']
      }
    )
  end
end
