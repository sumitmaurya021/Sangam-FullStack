class ProfileHighlight < ApplicationRecord
  belongs_to :user
  has_many   :highlight_stories, dependent: :destroy
  has_many   :stories, through: :highlight_stories

  validates :name,  presence: true, length: { maximum: 15 }
  validates :name,  uniqueness: { scope: :user_id }
  validates :emoji, length: { maximum: 4 }

  scope :ordered, -> { order(:position, :created_at) }

  def cover_story
    stories.order('highlight_stories.position ASC').first
  end

  def cover_media_url(routes)
    story = cover_story
    return nil unless story
    if story.media.attached?
      routes.rails_blob_path(story.media, only_path: true) rescue nil
    end
  end
end
