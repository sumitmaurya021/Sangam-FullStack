# Publishes a scheduled post at the right time.
# Enqueued on post creation: PublishScheduledPostJob.set(wait_until: post.scheduled_at).perform_later(post.id)
class PublishScheduledPostJob < ApplicationJob
  queue_as :default

  discard_on ActiveRecord::RecordNotFound

  def perform(post_id)
    post = Post.find(post_id)
    return if post.published?
    return unless post.scheduled_at.present? && post.scheduled_at <= Time.current

    post.update!(published: true)
    Rails.logger.info "PublishScheduledPostJob: post ##{post_id} published."
  end
end
