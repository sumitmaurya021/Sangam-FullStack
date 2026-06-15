class CloseFriend < ApplicationRecord
  belongs_to :user
  belongs_to :close_friend, class_name: 'User'

  validates :close_friend_id, uniqueness: { scope: :user_id }
  validate  :not_self

  private

  def not_self
    errors.add(:close_friend, "can't be yourself") if user_id == close_friend_id
  end
end
