# Runs periodically to archive expired stories (auto-save them privately)
class ArchiveExpiredStoriesJob < ApplicationJob
  queue_as :default

  def perform
    expired = Story.expired.where(archived: false)
    count   = expired.update_all(archived: true)
    Rails.logger.info "ArchiveExpiredStoriesJob: archived #{count} stories."
  end
end
