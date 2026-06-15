class GroupChatMember < ApplicationRecord
  belongs_to :group_chat
  belongs_to :user

  ROLES = %w[member admin].freeze

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: { scope: :group_chat_id, message: 'already a member' }
end
