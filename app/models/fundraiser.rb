class Fundraiser < ApplicationRecord
  belongs_to :post

  STATUSES = %w[active completed cancelled].freeze

  validates :title,       presence: true, length: { maximum: 100 }
  validates :goal_amount, numericality: { greater_than: 0 }
  validates :status,      inclusion: { in: STATUSES }

  scope :active, -> { where(status: 'active') }

  def percentage
    return 0 if goal_amount.zero?
    [(raised_amount / goal_amount * 100).round, 100].min
  end

  def completed?
    raised_amount >= goal_amount
  end

  def days_remaining
    return nil unless ends_at
    [(ends_at.to_date - Date.today).to_i, 0].max
  end
end
