# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PushSubscriptions', type: :request do
  let(:user) { create(:user) }

  describe 'POST /push_subscriptions' do
    let(:valid_params) do
      {
        subscription: {
          endpoint: 'https://fcm.googleapis.com/fcm/send/sample_token_123',
          keys: {
            p256dh: 'BNc9rZgC-sample-key',
            auth: 'auth-secret-123'
          }
        }
      }
    end

    context 'when unauthenticated' do
      it 'redirects or rejects unauthenticated request' do
        post push_subscriptions_path, params: valid_params, as: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when authenticated' do
      before { sign_in user }

      it 'creates a new push subscription' do
        expect {
          post push_subscriptions_path, params: valid_params, as: :json
        }.to change(user.push_subscriptions, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('ok')
        expect(json['id']).to be_present
      end

      it 'updates an existing push subscription if endpoint matches' do
        existing = create(:push_subscription, user: user, endpoint: 'https://fcm.googleapis.com/fcm/send/sample_token_123')

        expect {
          post push_subscriptions_path, params: valid_params, as: :json
        }.not_to change(user.push_subscriptions, :count)

        expect(response).to have_http_status(:created)
      end

      it 'returns unprocessable_entity when params are missing' do
        post push_subscriptions_path, params: { subscription: { endpoint: '' } }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE /push_subscriptions' do
    before { sign_in user }
    let!(:subscription) { create(:push_subscription, user: user, endpoint: 'https://fcm.example.com/delete_me') }

    it 'deletes subscription by endpoint' do
      expect {
        delete push_subscriptions_path, params: { endpoint: 'https://fcm.example.com/delete_me' }, as: :json
      }.to change(user.push_subscriptions, :count).by(-1)

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json['status']).to eq('ok')
    end
  end

  describe 'GET /push_subscriptions/status' do
    before { sign_in user }

    it 'returns subscription status and vapid public key' do
      get status_push_subscriptions_path, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('subscribed')
      expect(json).to have_key('count')
      expect(json['vapid_public_key']).to eq(Rails.application.config.vapid_public_key)
    end
  end

  describe 'POST /push_subscriptions/test' do
    before { sign_in user }

    context 'when user has no subscriptions' do
      it 'returns 404 not found' do
        post test_push_subscriptions_path, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when user has subscriptions' do
      let!(:subscription) { create(:push_subscription, user: user) }

      it 'triggers test notification and returns ok' do
        expect(WebPushNotificationService).to receive(:send_to_user).and_return(1)

        post test_push_subscriptions_path, as: :json
        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json['status']).to eq('ok')
        expect(json['dispatched_count']).to eq(1)
      end
    end
  end
end
