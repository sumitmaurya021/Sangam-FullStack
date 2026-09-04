require 'rails_helper'

RSpec.describe Friendship, type: :model do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:friend).class_name('User') }
  end

  describe 'validations' do
    subject { create(:friendship, user: user1, friend: user2, status: 'pending') }
    it { should validate_uniqueness_of(:user_id).scoped_to(:friend_id).with_message('friendship already exists') }
    it { should validate_inclusion_of(:status).in_array(%w[pending accepted rejected]) }

    it 'prevents self friendship' do
      friendship = Friendship.new(user: user1, friend: user1, status: 'pending')
      expect(friendship).not_to be_valid
      expect(friendship.errors[:friend_id]).to include("can't be the same as user")
    end
  end

  describe 'methods' do
    let(:friendship) { create(:friendship, user: user1, friend: user2, status: 'pending') }

    it '#accept! updates status to accepted' do
      friendship.accept!
      expect(friendship.reload.status).to eq('accepted')
    end

    it '#reject! updates status to rejected' do
      friendship.reject!
      expect(friendship.reload.status).to eq('rejected')
    end
  end
end
