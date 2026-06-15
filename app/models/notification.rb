class Notification < ApplicationRecord
  belongs_to :recipient, class_name: 'User'
  belongs_to :actor, class_name: 'User'
  belongs_to :notifiable, polymorphic: true, optional: true

  TYPES = %w[
    like
    comment
    reply
    friend_request
    friend_accepted
    share
    mention
    reel_like
    reel_comment
    group_invite
    event_invite
    story_view
    follow
    birthday
    memory
    collab_invite
    collab_accepted
    marketplace_inquiry
    fundraiser_donation
    story_poll_vote
    story_qa_reply
    event_reminder
  ].freeze

  validates :notification_type, inclusion: { in: TYPES }

  scope :unread, -> { where(read_at: nil) }
  scope :read, -> { where.not(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user) { where(recipient: user) }

  # Don't notify yourself
  scope :valid, -> { where('recipient_id != actor_id') }

  def read?
    read_at.present?
  end

  def mark_as_read!
    update_column(:read_at, Time.current) unless read?
  end

  # Human-readable message based on type
  def notification_message
    actor_name = actor.name || 'Someone'
    case notification_type
    when 'like'
      # Use stored message if it has reaction emoji, else fallback
      message.present? ? message : "#{actor_name} reacted to your post"
    when 'comment'
      "#{actor_name} commented on your post"
    when 'reply'
      # Check if it's a reply to a comment or to the post owner
      if notifiable.is_a?(Comment) && notifiable.replied_to_user_id.present?
        "#{actor_name} replied to your comment"
      else
        "#{actor_name} replied to a comment on your post"
      end
    when 'friend_request'
      "#{actor_name} sent you a friend request"
    when 'friend_accepted'
      "#{actor_name} accepted your friend request"
    when 'share'
      "#{actor_name} shared your post"
    when 'mention'
      "#{actor_name} mentioned you in a post"
    when 'reel_like'
      "#{actor_name} liked your reel"
    when 'reel_comment'
      "#{actor_name} commented on your reel"
    when 'group_invite'
      "#{actor_name} invited you to a group"
    when 'event_invite'
      "#{actor_name} invited you to an event"
    when 'story_view'
      "#{actor_name} viewed your story"
    when 'follow'
      "#{actor_name} started following you"
    when 'birthday'
      "Today is #{actor_name}'s birthday! 🎂"
    when 'memory'
      "You have a memory from #{actor_name} years ago"
    when 'collab_invite'
      "#{actor_name} invited you to collaborate on a post"
    when 'collab_accepted'
      "#{actor_name} accepted your collaboration invite"
    when 'marketplace_inquiry'
      "#{actor_name} is interested in your listing"
    when 'fundraiser_donation'
      "#{actor_name} donated to your fundraiser"
    when 'story_poll_vote'
      "#{actor_name} voted on your story poll"
    when 'story_qa_reply'
      "#{actor_name} replied to your story Q&A"
    when 'event_reminder'
      "Reminder: #{message.presence || 'An event is coming up'}"
    else
      "#{actor_name} interacted with you"
    end
  end

  # Icon for each notification type
  def notification_icon
    case notification_type
    when 'like'    then 'like'
    when 'comment' then 'comment'
    when 'reply'   then 'reply'
    when 'friend_request', 'friend_accepted' then 'friend'
    when 'share'   then 'share'
    when 'mention' then 'mention'
    when 'reel_like', 'reel_comment' then 'reel'
    when 'group_invite' then 'group'
    when 'event_invite' then 'event'
    when 'story_view'   then 'story'
    when 'follow'       then 'friend'
    else 'bell'
    end
  end

  # URL to navigate to when notification is clicked
  def target_url(routes)
    case notification_type
    when 'like', 'comment', 'reply', 'share', 'mention'
      post = notifiable.is_a?(Post) ? notifiable : notifiable.try(:post)
      post ? routes.post_path(post) : routes.posts_path
    when 'friend_request', 'friend_accepted'
      routes.profile_path(actor)
    when 'follow'
      routes.profile_path(actor)
    else
      routes.posts_path
    end
  rescue
    routes.posts_path
  end

  # Broadcast to recipient via ActionCable
  def broadcast_to_recipient
    ActionCable.server.broadcast(
      "notifications_#{recipient_id}",
      {
        type: 'new_notification',
        notification: as_json_payload
      }
    )
    # Send email notification asynchronously (only in production, skip high-frequency types)
    if Rails.env.production? && !%w[story_view like reel_like].include?(notification_type)
      NotificationMailer.notification_email(self).deliver_later
    end
  rescue => e
    Rails.logger.error "Notification broadcast failed: #{e.message}"
  end

  def as_json_payload
    {
      id: id,
      notification_type: notification_type,
      message: notification_message,
      icon: notification_icon,
      read: read?,
      created_at: created_at.iso8601,
      friendship_id: (notifiable.is_a?(Friendship) ? notifiable.id : nil),
      friendship_accepted: (notifiable.is_a?(Friendship) ? notifiable.status == 'accepted' : false),
      actor: {
        id: actor.id,
        name: actor.name,
        avatar: actor_avatar_url
      }
    }
  end

  private

  def actor_avatar_url
    if actor.avatar.attached?
      Rails.application.routes.url_helpers.rails_blob_path(actor.avatar, only_path: true)
    else
      nil
    end
  rescue
    nil
  end
end
