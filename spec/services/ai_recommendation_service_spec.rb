require 'rails_helper'

RSpec.describe AiRecommendationService do
  describe '.rank_posts_for' do
    let(:user) { User.create!(name: 'Neural Tester', email: "neural_#{SecureRandom.hex(4)}@test.com", password: 'password123') }
    let(:friend) { User.create!(name: 'Friend User', email: "friend_#{SecureRandom.hex(4)}@test.com", password: 'password123') }

    before do
      Friendship.create!(user: user, friend: friend)
      Post.create!(user: friend, content: 'Friend neural post content')
      Post.create!(user: user, content: 'Own post content')
    end

    it 'ranks posts for user and attaches recommendation score percentage' do
      posts = AiRecommendationService.rank_posts_for(user)

      expect(posts).to be_an(Array)
      expect(posts.first).to respond_to(:recommendation_score_pct)
      expect(posts.first.recommendation_score_pct).to include('% Match')
    end
  end
end
