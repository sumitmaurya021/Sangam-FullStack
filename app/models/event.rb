class Event < ApplicationRecord
  belongs_to :organizer, class_name: 'User'
  has_one_attached :cover_photo

  has_many :event_responses, dependent: :destroy
  has_many :going_users,      -> { where(response: 'going') },
           through: :event_responses, source: :user
  has_many :interested_users, -> { where(response: 'interested') },
           through: :event_responses, source: :user

  PRIVACY_OPTIONS = %w[public friends private].freeze

  validates :title,     presence: true, length: { maximum: 200 }
  validates :starts_at, presence: true
  validates :privacy,   inclusion: { in: PRIVACY_OPTIONS }
  validate  :starts_at_in_future, on: :create

  scope :upcoming,  -> { where('starts_at > ?', Time.current).order(:starts_at) }
  scope :past,      -> { where('starts_at <= ?', Time.current).order(starts_at: :desc) }
  scope :public_events, -> { where(privacy: 'public') }
  scope :search,    ->(q) { where("title ILIKE ? OR description ILIKE ?", "%#{q}%", "%#{q}%") }

  def user_response(user)
    event_responses.find_by(user_id: user.id)&.response
  end

  def going?(user)
    event_responses.exists?(user_id: user.id, response: 'going')
  end

  def interested?(user)
    event_responses.exists?(user_id: user.id, response: 'interested')
  end

  private

  def starts_at_in_future
    errors.add(:starts_at, 'must be in the future') if starts_at.present? && starts_at < Time.current
  end
end
