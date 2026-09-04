require 'rails_helper'

RSpec.describe Story, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:story_views).dependent(:destroy) }
    it { should have_many(:viewers).through(:story_views).source(:user) }
    it { should have_many(:story_poll_votes).dependent(:destroy) }
    it { should have_many(:story_qa_replies).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:active_story) { create(:story, user: user, expires_at: 10.hours.from_now) }
    let!(:expired_story) { create(:story, user: user, expires_at: 2.hours.ago) }

    it 'returns active stories' do
      expect(Story.active).to include(active_story)
      expect(Story.active).not_to include(expired_story)
    end

    it 'returns expired stories' do
      expect(Story.expired).to include(expired_story)
      expect(Story.expired).not_to include(active_story)
    end
  end

  describe '#viewed_by?' do
    let(:story) { create(:story, user: user) }
    let(:viewer) { create(:user) }

    it 'returns true if viewer has viewed story' do
      expect(story.viewed_by?(viewer)).to be false
      StoryView.create!(story: story, user: viewer)
      expect(story.viewed_by?(viewer)).to be true
    end
  end

  describe '#active?' do
    it 'correctly checks active status' do
      active = build(:story, expires_at: 1.hour.from_now)
      expired = build(:story, expires_at: 1.hour.ago)

      expect(active.active?).to be true
      expect(expired.active?).to be false
    end
  end
end
