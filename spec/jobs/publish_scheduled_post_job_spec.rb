require 'rails_helper'

RSpec.describe PublishScheduledPostJob, type: :job do
  describe '#perform' do
    it 'publishes a scheduled post when its time has come' do
      post = create(:post, published: false, scheduled_at: 1.minute.ago)
      PublishScheduledPostJob.perform_now(post.id)
      expect(post.reload.published).to be true
    end

    it 'does not publish a post scheduled in the future' do
      post = create(:post, published: false, scheduled_at: 1.hour.from_now)
      PublishScheduledPostJob.perform_now(post.id)
      expect(post.reload.published).to be false
    end

    it 'does nothing if post is already published' do
      post = create(:post, published: true, scheduled_at: 1.minute.ago)
      PublishScheduledPostJob.perform_now(post.id)
      # No error raised and still published
      expect(post.reload.published).to be true
    end

    it 'discards silently when post not found' do
      expect { PublishScheduledPostJob.perform_now(999_999) }.not_to raise_error
    end
  end
end
