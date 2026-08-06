require 'rails_helper'

RSpec.describe FeedRankingService do
  let(:user) { create(:user) }
  let(:service) { FeedRankingService.new(user) }

  # Setup basic data
  let(:category_tech) { create(:category_tag, name: 'Technology', slug: 'technology') }
  let(:category_sports) { create(:category_tag, name: 'Sports', slug: 'sports') }

  let(:friend) do
    f = create(:user)
    create(:friendship, user: user, friend: f, status: 'accepted')
    create(:friendship, user: f, friend: user, status: 'accepted')
    f
  end

  let(:close_friend) do
    cf = create(:user)
    create(:friendship, user: user, friend: cf, status: 'accepted')
    create(:friendship, user: cf, friend: user, status: 'accepted')
    CloseFriend.create!(user: user, close_friend_id: cf.id)
    cf
  end

  let(:stranger) { create(:user) }

  before do
    # Clear cache before tests
    Rails.cache.clear
  end

  describe '#get_feed' do
    context 'when user has high affinity for Technology' do
      before do
        create(:user_tag_affinity, user: user, category_tag: category_tech, score: 50.0)
        create(:user_tag_affinity, user: user, category_tag: category_sports, score: 0.0)
      end

      it 'ranks Technology posts higher than Sports posts for the same engagement' do
        tech_post = create(:post, user: stranger, created_at: 1.hour.ago)
        create(:post_category_tag, post: tech_post, category_tag: category_tech, confidence_score: 0.9)

        sports_post = create(:post, user: stranger, created_at: 1.hour.ago)
        create(:post_category_tag, post: sports_post, category_tag: category_sports, confidence_score: 0.9)

        feed = service.get_feed(1, 10)
        
        expect(feed.first).to eq(tech_post)
        expect(feed.last).to eq(sports_post)
      end
    end

    context 'when checking engagement rate' do
      it 'ranks highly engaged posts above posts with no engagement' do
        boring_post = create(:post, user: stranger, views_count: 100, likes_count: 0, comments_count: 0)
        
        viral_post = create(:post, user: stranger, views_count: 100, likes_count: 20, comments_count: 10)

        feed = service.get_feed(1, 10)
        expect(feed.first).to eq(viral_post)
        expect(feed.last).to eq(boring_post)
      end
    end

    context 'when checking friend following boost' do
      it 'ranks close friends above regular friends, and friends above strangers' do
        stranger_post = create(:post, user: stranger, created_at: 1.hour.ago)
        friend_post = create(:post, user: friend, created_at: 1.hour.ago)
        close_friend_post = create(:post, user: close_friend, created_at: 1.hour.ago)

        feed = service.get_feed(1, 10)
        
        expect(feed[0]).to eq(close_friend_post)
        expect(feed[1]).to eq(friend_post)
        expect(feed[2]).to eq(stranger_post)
      end
    end

    context 'when checking recency' do
      it 'ranks newer posts higher than older posts all else being equal' do
        old_post = create(:post, user: stranger, created_at: 3.days.ago)
        new_post = create(:post, user: stranger, created_at: 1.hour.ago)

        feed = service.get_feed(1, 10)
        
        expect(feed.first).to eq(new_post)
        expect(feed.last).to eq(old_post)
      end
    end

    context 'when checking the re-rank logic (consecutive author capping)' do
      it 'does not show more than 2 consecutive posts from the same author' do
        # Create 4 highly engaging posts from the same friend (should be top ranked)
        post1 = create(:post, user: friend, created_at: 1.hour.ago, likes_count: 100)
        post2 = create(:post, user: friend, created_at: 2.hours.ago, likes_count: 90)
        post3 = create(:post, user: friend, created_at: 3.hours.ago, likes_count: 80)
        post4 = create(:post, user: friend, created_at: 4.hours.ago, likes_count: 70)

        # Create 1 normal post from a stranger
        stranger_post = create(:post, user: stranger, created_at: 5.hours.ago, likes_count: 0)

        feed = service.get_feed(1, 10)

        # Expected order: post1, post2, stranger_post. (post3 and post4 are filtered out from the top block)
        expect(feed[0]).to eq(post1)
        expect(feed[1]).to eq(post2)
        expect(feed[2]).to eq(stranger_post)
        expect(feed).not_to include(post3)
        expect(feed).not_to include(post4)
      end
    end
    
    context 'caching behavior' do
      it 'caches the feed results in Redis' do
        post = create(:post, user: stranger)
        
        allow(Rails.cache).to receive(:write).and_call_original
        expect(Rails.cache).to receive(:write).with(
          "feed_ranking:#{user.id}:page:1:per_page:5",
          [post.id],
          expires_in: 5.minutes
        )
        
        service.get_feed(1, 5)
      end
    end
  end
end
