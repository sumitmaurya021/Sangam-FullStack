require 'rails_helper'

RSpec.describe ArchiveExpiredStoriesJob, type: :job do
  describe '#perform' do
    it 'archives expired stories that are not yet archived' do
      expired_story = create(:story, expires_at: 2.hours.ago, archived: false)
      active_story  = create(:story, expires_at: 2.hours.from_now, archived: false)

      ArchiveExpiredStoriesJob.perform_now

      expect(expired_story.reload.archived).to be true
      expect(active_story.reload.archived).to be false
    end

    it 'does not re-archive already archived stories' do
      already_archived = create(:story, expires_at: 2.hours.ago, archived: true)

      expect {
        ArchiveExpiredStoriesJob.perform_now
      }.not_to change { already_archived.reload.archived }
    end

    it 'handles no expired stories gracefully' do
      create(:story, expires_at: 1.hour.from_now, archived: false)
      expect { ArchiveExpiredStoriesJob.perform_now }.not_to raise_error
    end
  end
end
