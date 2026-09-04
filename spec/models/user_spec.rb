require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_most(100) }
    it { should validate_length_of(:bio).is_at_most(500) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    it { should allow_value('https://example.com').for(:website_url) }
    it { should_not allow_value('invalid_url').for(:website_url) }
  end

  describe 'associations' do
    it { should have_many(:articles).dependent(:destroy) }
    it { should have_many(:posts).dependent(:destroy) }
    it { should have_many(:user_interactions).dependent(:destroy) }
    it { should have_many(:reels).dependent(:destroy) }
    it { should have_many(:reel_likes).dependent(:destroy) }
    it { should have_many(:reel_comments).dependent(:destroy) }
    it { should have_many(:stories).dependent(:destroy) }
    it { should have_many(:bookmarks).dependent(:destroy) }
    it { should have_many(:events).with_foreign_key(:organizer_id).dependent(:destroy) }
    it { should have_many(:event_responses).dependent(:destroy) }
    it { should have_many(:group_memberships).dependent(:destroy) }
    it { should have_many(:groups).through(:group_memberships) }
    it { should have_many(:sent_conversations).class_name('Conversation').with_foreign_key('sender_id').dependent(:destroy) }
    it { should have_many(:received_conversations).class_name('Conversation').with_foreign_key('recipient_id').dependent(:destroy) }
    it { should have_many(:messages).dependent(:destroy) }
    it { should have_many(:owned_group_chats).class_name('GroupChat').with_foreign_key('owner_id').dependent(:destroy) }
    it { should have_many(:group_chat_members).dependent(:destroy) }
    it { should have_many(:group_chats).through(:group_chat_members) }
    it { should have_many(:group_chat_messages).dependent(:destroy) }
    it { should have_many(:likes).dependent(:destroy) }
    it { should have_many(:liked_posts).through(:likes).source(:post) }
    it { should have_many(:comments).dependent(:destroy) }
    it { should have_many(:shares).dependent(:destroy) }
    it { should have_many(:notifications).with_foreign_key(:recipient_id).dependent(:destroy) }
    it { should have_many(:sent_notifications).class_name('Notification').with_foreign_key(:actor_id).dependent(:destroy) }
    it { should have_many(:bookmark_collections).dependent(:destroy) }
    it { should have_many(:profile_highlights).dependent(:destroy) }
    it { should have_many(:close_friend_records).class_name('CloseFriend').with_foreign_key(:user_id).dependent(:destroy) }
    it { should have_many(:marketplace_listings).dependent(:destroy) }
    it { should have_one(:digital_twin).dependent(:destroy) }
    it { should have_many(:digital_twin_logs).dependent(:destroy) }
    it { should have_one(:ux_mutation_preference).dependent(:destroy) }
    it { should have_many(:ux_telemetry_events).dependent(:destroy) }
    it { should have_many(:synapse_streams).dependent(:destroy) }
    it { should have_many(:active_follows).class_name('Follow').with_foreign_key('follower_id').dependent(:destroy) }
    it { should have_many(:passive_follows).class_name('Follow').with_foreign_key('followee_id').dependent(:destroy) }
    it { should have_many(:following).through(:active_follows).source(:followee) }
    it { should have_many(:followers).through(:passive_follows).source(:follower) }
  end

  describe 'scopes' do
    it 'returns super admins' do
      regular_user = create(:user)
      admin_user = create(:user, :super_admin)
      expect(User.super_admins).to include(admin_user)
      expect(User.super_admins).not_to include(regular_user)
    end
  end

  describe '#super_admin?' do
    it 'returns true for super admins' do
      admin = create(:user, :super_admin)
      expect(admin.super_admin?).to be true
    end

    it 'returns false for regular users' do
      user = create(:user)
      expect(user.super_admin?).to be false
    end
  end

  describe '#display_name' do
    it 'returns name if present' do
      user = build(:user, name: 'Alice Smith')
      expect(user.display_name).to eq('Alice Smith')
    end

    it 'returns email prefix if name is blank' do
      user = build(:user, name: '', email: 'john.doe@example.com')
      expect(user.display_name).to eq('john.doe')
    end
  end

  describe 'follows' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'allows user to follow and unfollow another user' do
      expect(user1.following?(user2)).to be false

      user1.follow!(user2)
      expect(user1.following?(user2)).to be true
      expect(user2.followers).to include(user1)

      user1.unfollow!(user2)
      expect(user1.following?(user2)).to be false
    end
  end

  describe 'online status management' do
    let(:user) { create(:user) }

    it 'marks user online and offline' do
      user.mark_online!
      expect(user.reload.online).to be true
      expect(user.online_status).to eq('online')

      user.mark_offline!
      expect(user.reload.online).to be false
    end

    it 'always returns online for AI bot' do
      ai_user = create(:user, :ai_bot)
      expect(ai_user.online?).to be true
    end
  end

  describe '2FA & OTP verification' do
    let(:user) { create(:user, :with_2fa) }

    it 'validates OTP code correctly' do
      totp = ROTP::TOTP.new(user.otp_secret, issuer: 'Sangam')
      current_code = totp.now

      expect(user.valid_otp?(current_code)).to be_truthy
      expect(user.valid_otp?('000000')).to be_falsy
    end

    it 'returns false if 2FA is disabled' do
      plain_user = create(:user)
      expect(plain_user.valid_otp?('123456')).to be false
    end
  end

  describe 'close friends' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it 'toggles close friend status' do
      expect(user1.close_friends_with?(user2)).to be false

      user1.toggle_close_friend!(user2)
      expect(user1.close_friends_with?(user2)).to be true

      user1.toggle_close_friend!(user2)
      expect(user1.close_friends_with?(user2)).to be false
    end
  end

  describe '.from_omniauth' do
    let(:auth_hash) do
      OmniAuth::AuthHash.new(
        provider: 'google_oauth2',
        uid: '123456789',
        info: {
          email: 'oauth_user@example.com',
          name: 'OAuth User'
        }
      )
    end

    it 'creates a new user from omniauth payload' do
      expect {
        user = User.from_omniauth(auth_hash)
        expect(user.email).to eq('oauth_user@example.com')
        expect(user.provider).to eq('google_oauth2')
        expect(user.uid).to eq('123456789')
      }.to change(User, :count).by(1)
    end

    it 'links omniauth to existing user by email' do
      existing_user = create(:user, email: 'oauth_user@example.com')

      expect {
        user = User.from_omniauth(auth_hash)
        expect(user.id).to eq(existing_user.id)
        expect(user.reload.provider).to eq('google_oauth2')
      }.not_to change(User, :count)
    end
  end

  describe '.ai_bot' do
    it 'creates or fetches the singleton AI bot user' do
      bot = User.ai_bot
      expect(User.ai_bot.id).to eq(bot.id)
    end
  end

  describe 'friendship helpers & optimizations' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:user_c) { create(:user) }

    before do
      # user_a -> user_b (accepted, direct)
      create(:friendship, user: user_a, friend: user_b, status: 'accepted')
      # user_c -> user_a (accepted, inverse)
      create(:friendship, user: user_c, friend: user_a, status: 'accepted')
    end

    it 'returns all friend IDs (both direct and inverse) via all_friend_ids' do
      expect(user_a.all_friend_ids).to match_array([user_b.id, user_c.id])
      expect(user_b.all_friend_ids).to include(user_a.id)
      expect(user_c.all_friend_ids).to include(user_a.id)
    end

    it 'computes all_friends_count without N+1 queries' do
      expect(user_a.all_friends_count).to eq(2)
      expect(user_b.all_friends_count).to eq(1)
    end

    it 'correctly checks friends_with? for direct and inverse friends' do
      expect(user_a.friends_with?(user_b)).to be true
      expect(user_a.friends_with?(user_c)).to be true
      expect(user_b.friends_with?(user_a)).to be true
      expect(user_c.friends_with?(user_a)).to be true

      stranger = create(:user)
      expect(user_a.friends_with?(stranger)).to be false
      expect(user_a.friends_with?(nil)).to be false
    end

    it 'correctly tracks friend_request_pending? for sent and received requests' do
      user_d = create(:user)
      user_e = create(:user)

      # user_a sent to user_d
      create(:friendship, user: user_a, friend: user_d, status: 'pending')
      # user_e sent to user_a
      create(:friendship, user: user_e, friend: user_a, status: 'pending')

      expect(user_a.friend_request_pending?(user_d)).to be true
      expect(user_a.friend_request_pending?(user_e)).to be true
      expect(user_d.friend_request_pending?(user_a)).to be true
      expect(user_e.friend_request_pending?(user_a)).to be true
      expect(user_a.friend_request_pending?(user_b)).to be false
    end

    it 'computes mutual friends and mutual_friends_count accurately' do
      # user_b and user_c both have user_a as a mutual friend
      expect(user_b.mutual_friends_with(user_c)).to include(user_a)
      expect(user_b.mutual_friends_count(user_c)).to eq(1)
    end
  end
end
