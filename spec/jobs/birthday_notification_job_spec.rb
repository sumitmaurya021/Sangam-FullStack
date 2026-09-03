require 'rails_helper'

RSpec.describe BirthdayNotificationJob, type: :job do
  describe '#perform' do
    it 'creates birthday notifications for friends' do
      today = Date.today
      birthday_user = create(:user, birthday: today)
      friend = create(:user)

      # Create accepted friendship
      create(:friendship, user: birthday_user, friend: friend, status: 'accepted')
      create(:friendship, user: friend, friend: birthday_user, status: 'accepted')

      expect {
        BirthdayNotificationJob.perform_now
      }.to change(Notification, :count).by_at_least(1)
    end

    it 'does not duplicate birthday notifications' do
      today = Date.today
      birthday_user = create(:user, birthday: today)
      friend = create(:user)
      create(:friendship, user: birthday_user, friend: friend, status: 'accepted')
      create(:friendship, user: friend, friend: birthday_user, status: 'accepted')

      # Create an already-sent notification
      Notification.create!(
        recipient: friend,
        actor: birthday_user,
        notification_type: 'birthday',
        message: "Birthday!",
        created_at: Time.current
      )

      expect {
        BirthdayNotificationJob.perform_now
      }.not_to change(Notification, :count)
    end

    it 'does nothing when no users have birthdays today' do
      create(:user, birthday: Date.today - 1.day)
      expect { BirthdayNotificationJob.perform_now }.not_to raise_error
    end
  end
end
