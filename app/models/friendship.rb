class Friendship < ApplicationRecord
  belongs_to :user
  belongs_to :friend, class_name: 'User'

  validates :user_id, uniqueness: { scope: :friend_id, message: "friendship already exists" }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  validate :not_self_friendship

  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }

  def accept!
    update(status: 'accepted')
  end

  def reject!
    update(status: 'rejected')
  end

  private

  def not_self_friendship
    errors.add(:friend_id, "can't be the same as user") if user_id == friend_id
  end
end
