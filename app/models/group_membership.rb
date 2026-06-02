class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  ROLES   = %w[owner admin member].freeze
  STATUSES = %w[active pending banned].freeze

  validates :role,   inclusion: { in: ROLES }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :group_id }

  scope :active,  -> { where(status: 'active') }
  scope :pending, -> { where(status: 'pending') }
  scope :admins,  -> { where(role: %w[owner admin]) }

  after_create  :increment_members_count
  after_destroy :decrement_members_count

  private

  def increment_members_count
    group.increment!(:members_count) if status == 'active'
  end

  def decrement_members_count
    group.decrement!(:members_count) if status == 'active'
  end
end
