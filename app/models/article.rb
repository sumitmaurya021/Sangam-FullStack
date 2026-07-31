class Article < ApplicationRecord
  belongs_to :user

  has_rich_text :content
  has_one_attached :cover_image

  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :content, presence: true

  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }

  after_commit :enqueue_embedding_generation, on: [:create, :update]

  private

  def enqueue_embedding_generation
    GenerateEmbeddingJob.perform_later('Article', id)
  end
end
