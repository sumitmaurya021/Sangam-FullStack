require 'rails_helper'

RSpec.describe Comment, type: :model do
  let(:post_author) { create(:user) }
  let(:commenter) { create(:user) }
  let(:post) { create(:post, user: post_author) }

  describe 'validations' do
    subject { build(:comment, user: commenter, post: post) }

    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(1000) }
    it { should validate_presence_of(:user) }
    it { should validate_presence_of(:post) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:post).counter_cache(:comments_count) }
    it { should belong_to(:parent).class_name('Comment').optional.counter_cache(:replies_count) }
    it { should have_many(:replies).class_name('Comment').with_foreign_key(:parent_id).dependent(:destroy) }
    it { should belong_to(:replied_to_user).class_name('User').optional }
  end

  describe 'scopes' do
    let!(:top_comment) { create(:comment, user: commenter, post: post) }
    let!(:reply_comment) { create(:comment, user: commenter, post: post, parent: top_comment) }

    it 'returns top level comments' do
      expect(Comment.top_level).to include(top_comment)
      expect(Comment.top_level).not_to include(reply_comment)
    end
  end

  describe 'notifications on creation' do
    it 'creates notification for post author when top level comment is created' do
      expect {
        create(:comment, user: commenter, post: post)
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.recipient).to eq(post_author)
      expect(notification.actor).to eq(commenter)
      expect(notification.notification_type).to eq('comment')
    end

    it 'does not create notification if author comments on own post' do
      expect {
        create(:comment, user: post_author, post: post)
      }.not_to change(Notification, :count)
    end

    it 'notifies parent commenter on reply' do
      top_comment = create(:comment, user: commenter, post: post)
      replier = create(:user)

      expect {
        create(:comment, user: replier, post: post, parent: top_comment, replied_to_user: commenter)
      }.to change(Notification, :count).by(2) # Post author + parent commenter
    end
  end
end
