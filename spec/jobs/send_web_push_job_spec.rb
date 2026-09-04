# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SendWebPushJob, type: :job do
  let(:user) { create(:user) }

  it 'enqueues job in notifications queue' do
    expect {
      described_class.perform_later(user.id, { title: 'Test', body: 'Message' })
    }.to have_enqueued_job(described_class).on_queue('notifications')
  end

  it 'calls WebPushNotificationService.send_to_user when performed' do
    expect(WebPushNotificationService).to receive(:send_to_user).with(
      user,
      title: 'New Notification',
      body: 'Someone liked your post',
      icon: '/icon.svg',
      badge: nil,
      path: '/posts/1',
      tag: 'notif-1',
      data: {}
    )

    described_class.perform_now(
      user.id,
      {
        title: 'New Notification',
        body: 'Someone liked your post',
        icon: '/icon.svg',
        path: '/posts/1',
        tag: 'notif-1'
      }
    )
  end

  it 'gracefully returns if user does not exist' do
    expect(WebPushNotificationService).not_to receive(:send_to_user)
    expect {
      described_class.perform_now(999_999, { title: 'Test', body: 'Test' })
    }.not_to raise_error
  end
end
