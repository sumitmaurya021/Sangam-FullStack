class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :lockable,
         :omniauthable, omniauth_providers: %i[google_oauth2 github]

  # Active Storage Attachments
  has_one_attached :avatar
  has_one_attached :cover_photo

  # Associations
  has_many :articles, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_many :user_interactions, dependent: :destroy
  has_many :reels, dependent: :destroy
  has_many :reel_likes, dependent: :destroy
  has_many :reel_comments, dependent: :destroy
  has_many :stories, dependent: :destroy
  has_many :bookmarks, dependent: :destroy
  has_many :bookmarked_posts, -> { where(bookmarks: { bookmarkable_type: 'Post' }) },
           through: :bookmarks, source: :bookmarkable, source_type: 'Post'
  has_many :bookmarked_reels, -> { where(bookmarks: { bookmarkable_type: 'Reel' }) },
           through: :bookmarks, source: :bookmarkable, source_type: 'Reel'
  has_many :events, foreign_key: :organizer_id, dependent: :destroy, class_name: 'Event'
  has_many :event_responses, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships

  # Chat associations
  has_many :sent_conversations, class_name: 'Conversation', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_conversations, class_name: 'Conversation', foreign_key: 'recipient_id', dependent: :destroy
  has_many :messages, dependent: :destroy

  # Group chat associations
  has_many :owned_group_chats,   class_name: 'GroupChat', foreign_key: 'owner_id', dependent: :destroy
  has_many :group_chat_members,  dependent: :destroy
  has_many :group_chats,         through: :group_chat_members
  has_many :group_chat_messages, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :comments, dependent: :destroy
  has_many :shares, dependent: :destroy

  # Notifications
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_notifications, class_name: 'Notification', foreign_key: :actor_id, dependent: :destroy

  # Bookmark Collections
  has_many :bookmark_collections, dependent: :destroy

  # Profile Highlights
  has_many :profile_highlights, dependent: :destroy

  # Close Friends
  has_many :close_friend_records,  class_name: 'CloseFriend', foreign_key: :user_id, dependent: :destroy
  has_many :close_friends_list,    through: :close_friend_records, source: :close_friend

  # Marketplace
  has_many :marketplace_listings, dependent: :destroy

  # Digital Twin Proxy
  has_one :digital_twin, dependent: :destroy
  has_many :digital_twin_logs, dependent: :destroy


  # Post collaborations
  has_many :post_collaborators, dependent: :destroy
  has_many :collaborative_posts, through: :post_collaborators, source: :post

  # Friendshipsg
  has_many :friendships, dependent: :destroy
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id', dependent: :destroy
  has_many :friends, -> { where(friendships: { status: 'accepted' }) }, through: :friendships, source: :friend
  has_many :inverse_friends, -> { where(friendships: { status: 'accepted' }) }, through: :inverse_friendships, source: :user
  has_many :pending_friend_requests, -> { where(status: 'pending') }, class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :sent_friend_requests, -> { where(status: 'pending') }, class_name: 'Friendship', foreign_key: 'user_id'

  # Follows (Instagram-style one-way)
  has_many :active_follows,  class_name: 'Follow', foreign_key: 'follower_id', dependent: :destroy
  has_many :passive_follows, class_name: 'Follow', foreign_key: 'followee_id', dependent: :destroy
  has_many :following, through: :active_follows,  source: :followee
  has_many :followers, through: :passive_follows, source: :follower

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }
  validates :website_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: 'must be a valid URL' }, allow_blank: true

  # Scopes
  scope :super_admins, -> { where(super_admin: true) }

  # Methods
  def super_admin?
    super_admin == true
  end

  def display_name
    name.presence || email.to_s.split('@').first
  end
  alias_method :username, :display_name

  def all_friends
    friends + inverse_friends
  end

  def friends_with?(user)
    all_friends.include?(user)
  end

  def friend_request_pending?(user)
    sent_friend_requests.exists?(friend_id: user.id) || 
    pending_friend_requests.exists?(user_id: user.id)
  end

  def follow!(other_user)
    active_follows.find_or_create_by!(followee: other_user)
  end

  def unfollow!(other_user)
    active_follows.find_by(followee: other_user)&.destroy
  end

  def following?(other_user)
    active_follows.exists?(followee_id: other_user.id)
  end

  def liked?(post)
    if post.likes.loaded?
      post.likes.any? { |like| like.user_id == self.id }
    else
      likes.exists?(post_id: post.id)
    end
  end

  def conversations
    Conversation.involving(self).recent
  end

  def unread_notifications_count
    notifications.unread.count
  end

  def total_unread_messages
    Conversation.involving(self).sum { |c| c.unread_count_for(self) }
  end

  def mark_online!
    update_columns(online: true, last_seen_at: Time.current)
  end

  def mark_offline!
    update_columns(online: false, last_seen_at: Time.current)
  end

  def online?
    is_ai? || self[:online]
  end

  def online
    is_ai? || self[:online]
  end

  def online_status
    online? ? 'online' : (last_seen_at ? "Last seen #{ActionController::Base.helpers.time_ago_in_words(last_seen_at)} ago" : 'Offline')
  end

  def close_friends_with?(user)
    close_friend_records.exists?(close_friend_id: user.id)
  end

  def toggle_close_friend!(user)
    record = close_friend_records.find_by(close_friend_id: user.id)
    record ? record.destroy : close_friend_records.create!(close_friend: user)
  end

  def birthday_today?
    birthday.present? && birthday.month == Date.today.month && birthday.day == Date.today.day
  end

  def mutual_friends_with(user)
    all_friends & user.all_friends
  end

  # ─── 2FA helpers ──────────────────────────────────────────────────────────
  def two_factor_enabled?
    otp_enabled? && otp_secret.present?
  end

  def valid_otp?(code)
    return false unless two_factor_enabled?
    ROTP::TOTP.new(otp_secret, issuer: 'Sangam')
              .verify(code.to_s.strip.gsub(/\s/, ''), drift_behind: 30)
  end

  # ─── OAuth ────────────────────────────────────────────────────────────────
  # Find or create a user from an OmniAuth hash (Google / GitHub).
  # Rules:
  #   1. If a user with the same provider+uid already exists → return it.
  #   2. If a user with the same email exists → link the provider to that account.
  #   3. Otherwise → create a brand-new user (no password required for OAuth accounts).
  def self.from_omniauth(auth)
    # 1. Existing OAuth link
    user = find_by(provider: auth.provider, uid: auth.uid.to_s)
    return user if user

    # 2. Email-based lookup (link accounts)
    email = auth.info.email.to_s.downcase.strip
    user  = find_by(email: email) if email.present?

    if user
      # Link provider to existing account
      user.update_columns(provider: auth.provider, uid: auth.uid.to_s)
      return user
    end

    # 3. Create new user
    user = new(
      provider:  auth.provider,
      uid:       auth.uid.to_s,
      email:     email,
      name:      auth.info.name.presence || auth.info.nickname.presence || email.split('@').first,
      password:  Devise.friendly_token(40),   # random, user never needs to know it
      confirmed_at: Time.current              # skip email confirmation for OAuth users
    )
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)
    user.save
    user
  end

  # ─── AI Assistant ─────────────────────────────────────────────────────────
  def self.ai_bot
    find_or_create_by!(email: 'ai@sangam.com') do |user|
      user.name = 'AI Assistant ✨'
      user.password = SecureRandom.hex(20)
      user.is_ai = true
      user.confirmed_at = Time.current
    end
  end
end
