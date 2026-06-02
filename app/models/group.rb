class Group < ApplicationRecord
  belongs_to :owner, class_name: 'User'
  has_one_attached :cover_photo
  has_one_attached :avatar

  has_many :group_memberships, dependent: :destroy
  has_many :members, through: :group_memberships, source: :user
  has_many :posts, dependent: :nullify

  PRIVACY_OPTIONS = %w[public private secret].freeze

  validates :name,    presence: true, length: { maximum: 100 }
  validates :privacy, inclusion: { in: PRIVACY_OPTIONS }

  scope :public_groups,  -> { where(privacy: 'public') }
  scope :recent,         -> { order(created_at: :desc) }
  scope :search,         ->(q) { where("name ILIKE ? OR description ILIKE ?", "%#{q}%", "%#{q}%") }

  after_create :add_owner_as_admin

  def member?(user)
    group_memberships.active.exists?(user_id: user.id)
  end

  def admin?(user)
    group_memberships.where(user: user, role: %w[owner admin]).exists?
  end

  def pending_member?(user)
    group_memberships.pending.exists?(user_id: user.id)
  end

  private

  def add_owner_as_admin
    group_memberships.create!(user: owner, role: 'owner', status: 'active')
    increment!(:members_count)
  end
end
