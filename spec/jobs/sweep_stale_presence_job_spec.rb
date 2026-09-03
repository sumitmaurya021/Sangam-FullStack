require 'rails_helper'

RSpec.describe SweepStalePresenceJob, type: :job do
  describe '#perform' do
    it 'marks stale online users as offline' do
      stale_user = create(:user, online: true, last_seen_at: 5.minutes.ago)
      active_user = create(:user, online: true, last_seen_at: 30.seconds.ago)

      allow(ActionCable.server).to receive(:broadcast)

      SweepStalePresenceJob.perform_now

      expect(stale_user.reload.online).to be false
      expect(active_user.reload.online).to be true
    end

    it 'broadcasts presence update for swept users' do
      stale_user = create(:user, online: true, last_seen_at: 5.minutes.ago)

      expect(ActionCable.server).to receive(:broadcast).with(
        'user_presence',
        hash_including(type: 'presence_update', user_id: stale_user.id, online: false)
      )

      SweepStalePresenceJob.perform_now
    end

    it 'does not sweep recently active users' do
      active_user = create(:user, online: true, last_seen_at: 10.seconds.ago)
      allow(ActionCable.server).to receive(:broadcast)
      SweepStalePresenceJob.perform_now
      expect(active_user.reload.online).to be true
    end
  end
end
