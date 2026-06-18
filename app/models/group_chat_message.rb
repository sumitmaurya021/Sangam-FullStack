class GroupChatMessage < ApplicationRecord
  belongs_to :group_chat
  belongs_to :user

  has_one_attached :attachment

  MESSAGE_TYPES = %w[text image file audio].freeze

  validates :group_chat_id, presence: true
  validates :user_id,       presence: true
  validates :message_type,  inclusion: { in: MESSAGE_TYPES }
  validates :body,          presence: true, if: -> { message_type == 'text' }

  scope :visible, -> { where(deleted: false) }
  scope :recent,  -> { order(created_at: :asc) }

  after_commit :broadcast_to_group, on: :create

  def soft_delete!
    update!(deleted: true)
    ActionCable.server.broadcast(
      "group_chat_#{group_chat_id}",
      { type: 'group_message_deleted', message_id: id }
    )
  end

  def attachment_url
    return nil unless attachment.attached?
    Rails.application.routes.url_helpers.rails_blob_path(attachment, only_path: true)
  rescue
    nil
  end

  def as_json_payload
    {
      id:           id,
      body:         deleted ? nil : body,
      message_type: message_type,
      deleted:      deleted,
      created_at:   created_at.iso8601,
      user: {
        id:     user.id,
        name:   user.name,
        avatar: user.avatar.attached? ? avatar_path : nil
      },
      attachment_url:          deleted ? nil : attachment_url,
      attachment_filename:     attachment.attached? ? attachment.filename.to_s : nil,
      attachment_content_type: attachment.attached? ? attachment.content_type : nil
    }
  end

  private

  def broadcast_to_group
    ActionCable.server.broadcast(
      "group_chat_#{group_chat_id}",
      { type: 'new_group_message', message: as_json_payload }
    )
    # Touch parent so sidebar order updates
    group_chat.touch
  rescue => e
    Rails.logger.error "GroupChatMessage broadcast failed: #{e.message}"
  end

  def avatar_path
    Rails.application.routes.url_helpers.rails_blob_path(user.avatar, only_path: true)
  rescue
    nil
  end
end
