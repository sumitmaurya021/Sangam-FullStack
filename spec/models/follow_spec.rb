require 'rails_helper'

RSpec.describe Follow, type: :model do
  subject(:follow) { build(:follow) }

  # Associations
  it { is_expected.to belong_to(:follower).class_name('User') }
  it { is_expected.to belong_to(:followee).class_name('User') }

  # Validations
  describe 'uniqueness' do
    let(:alice) { create(:user) }
    let(:bob)   { create(:user) }

    it 'prevents duplicate follows' do
      create(:follow, follower: alice, followee: bob)
      duplicate = build(:follow, follower: alice, followee: bob)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:follower_id]).to be_present
    end
  end

  describe '#cannot_follow_self' do
    it 'is invalid when follower == followee' do
      user = create(:user)
      self_follow = build(:follow, follower: user, followee: user)
      expect(self_follow).not_to be_valid
      expect(self_follow.errors[:followee_id]).to be_present
    end
  end

  describe 'User#follow! / unfollow! / following?' do
    let(:alice) { create(:user) }
    let(:bob)   { create(:user) }

    it 'alice can follow bob' do
      alice.follow!(bob)
      expect(alice.following?(bob)).to be true
    end

    it 'alice can unfollow bob' do
      alice.follow!(bob)
      alice.unfollow!(bob)
      expect(alice.following?(bob)).to be false
    end

    it 'increments followers_count on bob' do
      expect { alice.follow!(bob) }.to change { bob.reload.followers_count }.by(1)
    end

    it 'increments following_count on alice' do
      expect { alice.follow!(bob) }.to change { alice.reload.following_count }.by(1)
    end

    it 'decrements counts on unfollow' do
      alice.follow!(bob)
      expect { alice.unfollow!(bob) }
        .to change { bob.reload.followers_count }.by(-1)
        .and change { alice.reload.following_count }.by(-1)
    end

    it 'bob following alice is independent' do
      alice.follow!(bob)
      expect(bob.following?(alice)).to be false
    end
  end
end
