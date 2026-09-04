require 'rails_helper'

RSpec.describe PollExpiryJob, type: :job do
  describe '#perform' do
    it 'expires a poll past its ends_at time' do
      # Create with future date then bypass validation to set past date
      poll = create(:poll, ends_at: 1.day.from_now, expired: false)
      poll.update_columns(ends_at: 1.minute.ago)

      PollExpiryJob.perform_now(poll.id)
      expect(poll.reload.expired).to be true
    end

    it 'does not expire a poll that ends in the future' do
      poll = create(:poll, ends_at: 1.hour.from_now, expired: false)
      PollExpiryJob.perform_now(poll.id)
      expect(poll.reload.expired).to be false
    end

    it 'does nothing if poll is already expired' do
      poll = create(:poll, ends_at: 1.day.from_now, expired: false)
      poll.update_columns(ends_at: 1.minute.ago, expired: true)
      PollExpiryJob.perform_now(poll.id)
      # Still expired, no error
      expect(poll.reload.expired).to be true
    end

    it 'discards silently if poll not found' do
      expect { PollExpiryJob.perform_now(999_999) }.not_to raise_error
    end
  end
end
