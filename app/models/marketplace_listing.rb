class MarketplaceListing < ApplicationRecord
  belongs_to :user
  has_many_attached :images
  has_many :marketplace_messages, dependent: :destroy

  CATEGORIES = %w[
    electronics furniture clothing vehicles property
    sports books toys garden other
  ].freeze

  CONDITIONS = %w[new like_new good fair poor].freeze
  STATUSES   = %w[active sold reserved].freeze

  validates :title,     presence: true, length: { maximum: 100 }
  validates :category,  inclusion: { in: CATEGORIES }
  validates :condition, inclusion: { in: CONDITIONS }
  validates :status,    inclusion: { in: STATUSES }
  validates :price,     numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  scope :active,    -> { where(status: 'active') }
  scope :recent,    -> { order(created_at: :desc) }
  scope :by_category, ->(cat) { where(category: cat) }
  scope :search,    ->(q) { where('title ILIKE ? OR description ILIKE ?', "%#{q}%", "%#{q}%") }

  def formatted_price
    return 'Free' if price.nil? || price.zero?
    "$#{'%.2f' % price}#{' (OBO)' if price_negotiable?}"
  end

  def cover_image
    images.first
  end

  def mark_sold!
    update!(status: 'sold')
  end
end
