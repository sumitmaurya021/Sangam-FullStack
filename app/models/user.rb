class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Active Storage Attachments
  has_one_attached :avatar
  has_one_attached :cover_photo

  # Associations
  has_many :posts, dependent: :destroy

  # Chat associations
  has_many :sent_conversations, class_name: 'Conversation', foreign_key: 'sender_id', dependent: :destroy
  has_many :received_conversations, class_name: 'Conversation', foreign_key: 'recipient_id', dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :comments, dependent: :destroy
  has_many :shares, dependent: :destroy

  # Notifications
  has_many :notifications, foreign_key: :recipient_id, dependent: :destroy
  has_many :sent_notifications, class_name: 'Notification', foreign_key: :actor_id, dependent: :destroy
  
  # Friendships
  has_many :friendships, dependent: :destroy
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id', dependent: :destroy
  has_many :friends, -> { where(friendships: { status: 'accepted' }) }, through: :friendships, source: :friend
  has_many :inverse_friends, -> { where(friendships: { status: 'accepted' }) }, through: :inverse_friendships, source: :user
  has_many :pending_friend_requests, -> { where(status: 'pending') }, class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :sent_friend_requests, -> { where(status: 'pending') }, class_name: 'Friendship', foreign_key: 'user_id'

  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :bio, length: { maximum: 500 }

  # Scopes
  scope :super_admins, -> { where(super_admin: true) }

  # Methods
  def super_admin?
    super_admin == true
  end
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

  def liked?(post)
    likes.exists?(post_id: post.id)
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

  def online_status
    online? ? 'online' : (last_seen_at ? "Last seen #{ActionController::Base.helpers.time_ago_in_words(last_seen_at)} ago" : 'Offline')
  end
end
