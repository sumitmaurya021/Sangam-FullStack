require 'rails_helper'

RSpec.describe Share, type: :model do
  let(:user) { create(:user) }
  let(:post_author) { create(:user) }
  let(:user_post) { create(:post, user: post_author) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post).counter_cache(:shares_count) }
  end

  describe 'validations' do
    subject { create(:share, user: user, post: user_post) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:post_id).with_message('has already shared this post') }
  end

  describe 'callbacks' do
    it 'creates a notification for post author on create' do
      expect {
        create(:share, user: user, post: user_post)
      }.to change(Notification, :count).by(1)
    end

    it 'does not create notification if author shares own post' do
      expect {
        create(:share, user: post_author, post: user_post)
      }.not_to change(Notification, :count)
    end
  end
end
