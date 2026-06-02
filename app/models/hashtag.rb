class Hashtag < ApplicationRecord
  has_many :post_hashtags, dependent: :destroy
  has_many :posts, through: :post_hashtags

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  before_validation :normalize_name

  scope :trending, -> { order(posts_count: :desc).limit(20) }
  scope :search,   ->(q) { where("name ILIKE ?", "%#{q}%") }

  def self.find_or_create_from_text!(text)
    tags = extract_tags(text)
    tags.map do |tag|
      find_or_create_by!(name: tag.downcase)
    end
  end

  def self.extract_tags(text)
    return [] if text.blank?
    text.scan(/#(\w+)/).flatten.uniq.map(&:downcase)
  end

  private

  def normalize_name
    self.name = name&.downcase&.gsub(/\A#/, '')
  end
end
