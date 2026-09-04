require 'rails_helper'

RSpec.describe EventReminderJob, type: :job do
  describe '#perform' do
    it 'sends reminder notifications for events starting within 24 hours' do
      organizer = create(:user)
      attendee  = create(:user)
      event = create(:event,
        organizer: organizer,
        starts_at: 2.hours.from_now,
        reminder_sent: false
      )
      create(:event_response, user: attendee, event: event, response: 'going')

      expect {
        EventReminderJob.perform_now
      }.to change(Notification, :count).by(1)

      expect(event.reload.reminder_sent).to be true
    end

    it 'does not send reminders for events that already had reminders sent' do
      organizer = create(:user)
      attendee  = create(:user)
      event = create(:event,
        organizer: organizer,
        starts_at: 2.hours.from_now,
        reminder_sent: true
      )
      create(:event_response, user: attendee, event: event, response: 'going')

      expect {
        EventReminderJob.perform_now
      }.not_to change(Notification, :count)
    end

    it 'does not send reminders for events more than 24 hours away' do
      organizer = create(:user)
      event = create(:event,
        organizer: organizer,
        starts_at: 30.hours.from_now,
        reminder_sent: false
      )
      expect {
        EventReminderJob.perform_now
      }.not_to change(Notification, :count)
    end
  end
end
