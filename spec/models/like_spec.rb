require 'rails_helper'

RSpec.describe Like, type: :model do
  let(:user) { create(:user) }
  let(:post_author) { create(:user) }
  let(:user_post) { create(:post, user: post_author) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post).counter_cache(:likes_count) }
  end

  describe 'validations' do
    subject { create(:like, user: user, post: user_post, reaction_type: 'like') }
    it { should validate_uniqueness_of(:user_id).scoped_to(:post_id).with_message('has already liked this post') }
    it { should validate_inclusion_of(:reaction_type).in_array(%w[like love haha wow sad angry]).with_message(/is not a valid reaction/) }
  end

  describe '#reaction_emoji' do
    it 'returns correct emoji for reaction type' do
      like = Like.new(reaction_type: 'love')
      expect(like.reaction_emoji).to eq('❤️')
    end
  end

  describe 'callbacks' do
    it 'creates a notification for post author on create' do
      expect {
        create(:like, user: user, post: user_post, reaction_type: 'like')
      }.to change(Notification, :count).by(1)
    end

    it 'does not create notification if author likes own post' do
      expect {
        create(:like, user: post_author, post: user_post, reaction_type: 'like')
      }.not_to change(Notification, :count)
    end
  end
end
