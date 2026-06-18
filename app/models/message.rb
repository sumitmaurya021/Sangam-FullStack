class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :user

  has_one_attached :attachment

  MESSAGE_TYPES = %w[text image file gif audio video].freeze

  validates :conversation_id, presence: true
  validates :user_id, presence: true
  validates :message_type, inclusion: { in: MESSAGE_TYPES }
  validates :body, presence: true, if: -> { message_type == 'text' }
  validates :attachment, presence: true, if: -> { message_type.in?(%w[image file gif audio video]) }

  scope :visible, -> { where(deleted: false) }
  scope :unread_by, ->(user) { where.not(user_id: user.id).where(read_at: nil) }
  scope :recent, -> { order(created_at: :asc) }

  # Use after_commit so broadcast happens AFTER transaction is committed
  # This ensures the record is visible to other DB connections (solid_cable polling)
  after_create :update_conversation_timestamp
  after_commit :broadcast_new_message, on: :create
  after_commit :trigger_ai_response, on: :create

  def read?
    read_at.present?
  end

  def sent_by?(user)
    self.user_id == user.id
  end

  def soft_delete!
    update!(deleted: true)
    broadcast_deletion
  end

  def attachment_url
    return nil unless attachment.attached?
    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  end

  def attachment_filename
    attachment.attached? ? attachment.filename.to_s : nil
  end

  def attachment_content_type
    attachment.attached? ? attachment.content_type : nil
  end

  private

  def trigger_ai_response
    # Check if this message was sent to the AI bot by a human
    ai_bot = User.find_by(email: 'ai@sangam.com')
    return unless ai_bot

    # If the sender is NOT the AI bot, and the conversation involves the AI bot
    if self.user_id != ai_bot.id && conversation.other_participant(self.user).id == ai_bot.id
      AiChatResponseJob.perform_later(self.id)
    end
  end

  def update_conversation_timestamp
    conversation.update_column(:last_message_at, created_at)
  end

  def broadcast_new_message
    payload = {
      type: 'new_message',
      message: message_data
    }

    # Broadcast to the conversation channel (both participants see it)
    ActionCable.server.broadcast("conversation_#{conversation_id}", payload)

    # Broadcast notification to each participant's personal channel
    [conversation.sender_id, conversation.recipient_id].each do |uid|
      next if uid.nil?
      unread = conversation.messages
                           .where.not(user_id: uid)
                           .where(read_at: nil)
                           .where(deleted: false)
                           .count
      ActionCable.server.broadcast(
        "user_chat_#{uid}",
        {
          type: 'new_message_notification',
          conversation_id: conversation_id,
          message: message_data,
          unread_count: unread
        }
      )
    end
  end

  def broadcast_deletion
    ActionCable.server.broadcast(
      "conversation_#{conversation_id}",
      { type: 'message_deleted', message_id: id }
    )
  end

  def message_data
    {
      id: id,
      body: deleted ? nil : body,
      message_type: message_type,
      user_id: user_id,
      sender_name: user.name,
      sender_avatar: user.avatar.attached? ? attachment_path_for(user.avatar) : nil,
      read_at: read_at&.iso8601,
      deleted: deleted,
      created_at: created_at.iso8601,
      attachment_url: deleted ? nil : attachment_url,
      attachment_filename: attachment_filename,
      attachment_content_type: attachment_content_type
    }
  end

  def attachment_path_for(blob)
    Rails.application.routes.url_helpers.rails_blob_path(blob, only_path: true)
  rescue
    nil
  end
end
