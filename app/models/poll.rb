class Poll < ApplicationRecord
  belongs_to :post
  has_many :poll_options, -> { order(:position) }, dependent: :destroy, inverse_of: :poll
  has_many :poll_votes,   dependent: :destroy

  validates :question,     presence: true, length: { maximum: 280 }
  validates :poll_options, length: { minimum: 2, maximum: 4,
                                     too_short: 'must have at least 2 options',
                                     too_long:  'can have at most 4 options' }
  validate  :ends_at_in_future, if: -> { ends_at.present? }

  accepts_nested_attributes_for :poll_options,
                                 reject_if:    ->(attrs) { attrs['body'].blank? },
                                 allow_destroy: false

  scope :active,  -> { where(expired: false).where('ends_at IS NULL OR ends_at > ?', Time.current) }
  scope :expired, -> { where('expired = TRUE OR (ends_at IS NOT NULL AND ends_at <= ?)', Time.current) }

  after_create :schedule_expiry_job

  # ── Totals ──────────────────────────────────────────────────────────────────
  def total_votes
    poll_options.sum(:votes_count)
  end

  # ── Status ──────────────────────────────────────────────────────────────────
  def active?
    !expired? && (ends_at.nil? || ends_at > Time.current)
  end

  def time_remaining
    return nil unless ends_at.present?
    return 'Ended' unless active?
    diff = ends_at - Time.current
    if    diff < 3600   then "#{(diff / 60).round}m left"
    elsif diff < 86_400 then "#{(diff / 3600).round}h left"
    else                     "#{(diff / 86_400).round}d left"
    end
  end

  # ── Expiry (called by PollExpiryJob) ───────────────────────────────────────
  def expire!
    update_column(:expired, true)
  end

  # ── Voting ──────────────────────────────────────────────────────────────────
  def voted_by?(user)
    poll_votes.exists?(user_id: user.id)
  end

  def vote_for!(user, option)
    return false unless active? && !voted_by?(user)
    transaction do
      poll_votes.create!(user: user, poll_option: option)
      option.increment!(:votes_count)
    end
    true
  rescue ActiveRecord::RecordNotUnique
    false
  end

  def user_choice(user)
    poll_votes.find_by(user: user)&.poll_option
  end

  private

  def schedule_expiry_job
    return unless ends_at.present?
    PollExpiryJob.set(wait_until: ends_at).perform_later(id)
  end

  def ends_at_in_future
    errors.add(:ends_at, 'must be in the future') if ends_at <= Time.current
  end
end
