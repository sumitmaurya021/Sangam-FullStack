require 'rails_helper'

RSpec.describe Post, type: :model do
  include ActiveJob::TestHelper

  let(:user) { create(:user) }

  describe 'validations' do
    subject { build(:post, user: user) }

    it { should validate_presence_of(:user) }
    it { should validate_inclusion_of(:visibility).in_array(Post::VISIBILITY_OPTIONS) }

    it 'requires content if poll is absent' do
      post = build(:post, user: user, content: nil)
      expect(post).not_to be_valid
      expect(post.errors[:content]).to include("can't be blank unless you add a poll")
    end

    it 'allows blank content if poll is present' do
      poll = build(:poll)
      poll.poll_options.build(body: 'Option 1')
      poll.poll_options.build(body: 'Option 2')
      post = build(:post, user: user, content: nil, poll: poll)
      expect(post).to be_valid
    end
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:group).optional }
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:likers).through(:likes).source(:user) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:shares).dependent(:destroy) }
    it { should have_many(:bookmarks).dependent(:destroy) }
    it { should have_many(:post_hashtags).dependent(:destroy) }
    it { should have_many(:hashtags).through(:post_hashtags) }
    it { should have_many(:post_mentions).dependent(:destroy) }
    it { should have_many(:post_category_tags).dependent(:destroy) }
    it { should have_many(:category_tags).through(:post_category_tags) }
    it { should have_one(:poll).dependent(:destroy) }
    it { should have_one(:fundraiser).dependent(:destroy) }
    it { should have_many(:post_collaborators).dependent(:destroy) }
  end

  describe 'scopes' do
    let!(:public_post) { create(:post, user: user, visibility: 'public', published: true) }
    let!(:scheduled_post) { create(:post, user: user, published: false, scheduled_at: 2.days.from_now) }

    it 'returns published posts' do
      expect(Post.published).to include(public_post)
      expect(Post.published).not_to include(scheduled_post)
    end

    it 'returns scheduled posts' do
      expect(Post.scheduled).to include(scheduled_post)
      expect(Post.scheduled).not_to include(public_post)
    end

    it 'searches post content' do
      special_post = create(:post, user: user, content: 'Unique ruby keyword in content')
      expect(Post.search('ruby')).to include(special_post)
      expect(Post.search('ruby')).not_to include(public_post)
    end

    it 'returns ranked feed posts' do
      expect(Post.ranked_feed(user)).to include(public_post)
    end
  end

  describe 'callbacks & background job enqueues' do
    it 'enqueues TagPostJob and GenerateEmbeddingJob on save' do
      expect {
        create(:post, user: user, content: 'Hello world #ruby')
      }.to have_enqueued_job(TagPostJob).and have_enqueued_job(GenerateEmbeddingJob)
    end

    it 'processes hashtags from content' do
      post = create(:post, user: user, content: 'Exploring #rails and #rspec')
      expect(post.hashtags.pluck(:name)).to match_array(%w[rails rspec])
    end

    it 'processes user mentions from content' do
      mentioned_user = create(:user, name: 'JohnDoe')
      post = create(:post, user: user, content: 'Check out @JohnDoe in this post')
      expect(post.mentioned_users).to include(mentioned_user)
    end
  end

  describe 'custom methods' do
    let(:post) { create(:post, user: user, content: 'Sample post') }
    let(:other_user) { create(:user) }

    it 'checks if liked by user' do
      expect(post.liked_by?(other_user)).to be false
      create(:like, user: other_user, post: post)
      expect(post.liked_by?(other_user)).to be true
    end

    it 'checks if bookmarked by user' do
      expect(post.bookmarked_by?(other_user)).to be false
      create(:bookmark, user: other_user, bookmarkable: post)
      expect(post.bookmarked_by?(other_user)).to be true
    end

    it 'increments views_count when tracked by another user' do
      expect {
        post.track_view!(other_user)
      }.to change { post.reload.views_count }.by(1)
    end

    it 'does not increment views_count when tracked by author' do
      expect {
        post.track_view!(user)
      }.not_to change { post.reload.views_count }
    end

    it 'checks location presence' do
      expect(post.has_location?).to be false
      post.location_name = 'New York'
      expect(post.has_location?).to be true
    end
  end
end
