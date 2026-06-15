require 'rails_helper'

RSpec.describe Story, type: :model do
  let(:author)   { create(:user) }
  let(:sharer)   { create(:user) }
  let(:post)     { Post.create!(user: author, content: 'Hello world', visibility: 'public') }

  describe 'shared_post story' do
    subject(:story) do
      Story.new(
        user:            sharer,
        story_type:      'shared_post',
        shared_post:     post,
        is_shared_post:  true
      )
    end

    it 'is valid with a shared_post reference' do
      expect(story).to be_valid
    end

    it 'has story_type shared_post in STORY_TYPES' do
      expect(Story::STORY_TYPES).to include('shared_post')
    end

    it 'sets expires_at automatically' do
      story.save!
      expect(story.expires_at).to be > Time.current
      expect(story.expires_at).to be_within(5.seconds).of(24.hours.from_now)
    end

    it 'is invalid without a shared_post reference' do
      bad = Story.new(user: sharer, story_type: 'shared_post', is_shared_post: true)
      expect(bad).not_to be_valid
      expect(bad.errors[:shared_post]).to be_present
    end

    it '#shared_post_story? returns true' do
      expect(story.shared_post_story?).to be true
    end

    it 'belongs_to shared_post' do
      story.save!
      expect(story.reload.shared_post).to eq post
    end
  end

  describe 'regular image story still works' do
    it 'is valid without shared_post' do
      s = Story.new(user: author, story_type: 'text',
                    caption: 'hi', background_color: '#111')
      expect(s).to be_valid
    end
  end
end
