# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebPushNotificationService do
  let(:user) { create(:user) }

  describe '.send_to_user' do
    context 'when user has no subscriptions' do
      it 'returns false without making any webpush calls' do
        expect(Webpush).not_to receive(:payload_send)
        result = described_class.send_to_user(
          user,
          title: 'Hello',
          body: 'World'
        )
        expect(result).to eq(false)
      end
    end

    context 'when user has an active subscription' do
      let!(:subscription) { create(:push_subscription, user: user) }

      it 'successfully sends push notification payload' do
        expect(Webpush).to receive(:payload_send).with(
          hash_including(
            endpoint: subscription.endpoint,
            p256dh: subscription.p256dh_key,
            auth: subscription.auth_key
          )
        ).and_return(true)

        result = described_class.send_to_user(
          user,
          title: 'New Message',
          body: 'Hey there!',
          path: '/conversations/1',
          tag: 'msg-1'
        )

        expect(result).to eq(1)
      end

      it 'destroys subscription when Webpush::ExpiredSubscription error is raised' do
        response = double('response', body: 'Subscription expired', code: '410')
        expect(Webpush).to receive(:payload_send).and_raise(
          Webpush::ExpiredSubscription.new(response, 'https://fcm.googleapis.com')
        )

        expect {
          described_class.send_to_user(user, title: 'Test', body: 'Expired')
        }.to change(PushSubscription, :count).by(-1)
      end

      it 'rescues unexpected errors without crashing' do
        expect(Webpush).to receive(:payload_send).and_raise(StandardError.new('Connection timeout'))

        expect {
          result = described_class.send_to_user(user, title: 'Test', body: 'Timeout')
          expect(result).to eq(0)
        }.not_to raise_error
      end
    end
  end
end
