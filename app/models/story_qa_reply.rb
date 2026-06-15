class StoryQaReply < ApplicationRecord
  belongs_to :story
  belongs_to :user

  validates :answer, presence: true, length: { maximum: 300 }
end
