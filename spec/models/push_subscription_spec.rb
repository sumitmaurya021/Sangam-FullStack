# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PushSubscription, type: :model do
  let(:user) { create(:user) }
  subject { build(:push_subscription, user: user) }

  describe 'validations' do
    it { should belong_to(:user) }
    it { should validate_presence_of(:endpoint) }
    it { should validate_presence_of(:p256dh_key) }
    it { should validate_presence_of(:auth_key) }

    it 'enforces uniqueness of endpoint scoped to user_id' do
      create(:push_subscription, user: user, endpoint: 'https://push.example.com/unique')
      duplicate = build(:push_subscription, user: user, endpoint: 'https://push.example.com/unique')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:endpoint]).to include('has already been taken')
    end

    it 'allows the same endpoint for different users' do
      create(:push_subscription, user: user, endpoint: 'https://push.example.com/shared')
      other_user = create(:user)
      other_sub = build(:push_subscription, user: other_user, endpoint: 'https://push.example.com/shared')
      expect(other_sub).to be_valid
    end
  end

  describe 'user association and cascading delete' do
    it 'destroys subscriptions when user is destroyed' do
      create(:push_subscription, user: user)
      expect { user.destroy }.to change(PushSubscription, :count).by(-1)
    end
  end
end
