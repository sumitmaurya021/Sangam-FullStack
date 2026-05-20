class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Associations
  has_many :posts, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :liked_posts, through: :likes, source: :post
  has_many :comments, dependent: :destroy
  has_many :shares, dependent: :destroy
  
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

  # Methods
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
end
