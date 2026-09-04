require 'rails_helper'

RSpec.describe FeedRankingService, type: :service do
  let(:user) { create(:user) }
  let(:friend) { create(:user) }
  let!(:friend_post) { create(:post, user: friend, content: 'Friend post content') }
  let!(:public_post) { create(:post, user: create(:user), content: 'Public post content') }

  before do
    user.follow!(friend)
  end

  describe '#get_feed' do
    it 'returns ranked posts for user' do
      service = FeedRankingService.new(user)
      feed = service.get_feed(1, 10)

      expect(feed).to include(friend_post)
      expect(feed).to include(public_post)
    end

    it 'caches post IDs for subsequent pages' do
      service = FeedRankingService.new(user)
      expect(Rails.cache).to receive(:write).at_least(:once)

      service.get_feed(1, 5)
    end
  end
end
