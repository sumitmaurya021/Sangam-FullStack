class PostCollaborator < ApplicationRecord
  belongs_to :post
  belongs_to :user

  STATUSES = %w[pending accepted rejected].freeze

  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :post_id }

  scope :accepted, -> { where(status: 'accepted') }
  scope :pending,  -> { where(status: 'pending') }

  def accept!
    update!(status: 'accepted')
  end

  def reject!
    update!(status: 'rejected')
  end
end
