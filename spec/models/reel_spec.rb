require 'rails_helper'

RSpec.describe Reel, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:reel_likes).dependent(:destroy) }
    it { should have_many(:likers).through(:reel_likes).source(:user) }
    it { should have_many(:reel_comments).dependent(:destroy) }
  end

  describe 'custom methods' do
    let(:reel) { create(:reel, user: user) }
    let(:viewer) { create(:user) }

    it 'checks if liked by user' do
      expect(reel.liked_by?(viewer)).to be false
      ReelLike.create!(user: viewer, reel: reel)
      expect(reel.liked_by?(viewer)).to be true
    end

    it 'increments views_count' do
      expect {
        reel.increment_views!
      }.to change { reel.reload.views_count }.by(1)
    end
  end
end
