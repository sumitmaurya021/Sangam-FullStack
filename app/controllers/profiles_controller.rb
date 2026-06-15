class ProfilesController < ApplicationController
  before_action :set_user, except: [:friends_list, :search]

  def show
    @posts           = @user.posts.published
                             .includes(:likes, :comments, :shares, :post_collaborators => :user)
                             .order(created_at: :desc)
    @friends_count   = @user.all_friends.count
    @posts_count     = @user.posts.published.count
    @followers_count = @user.followers_count
    @following_count = @user.following_count
    @highlights      = @user.profile_highlights.ordered
    @mutual_friends  = current_user == @user ? [] : current_user.mutual_friends_with(@user).first(6)
    @is_close_friend = current_user != @user && current_user.close_friends_with?(@user)
  end

  def friends
    @friends = @user.all_friends
  end

  def following
    @following = @user.following.order('follows.created_at DESC').page(params[:page]).per(20)
  end

  def followers
    @followers = @user.followers.order('follows.created_at DESC').page(params[:page]).per(20)
  end

  # JSON endpoint for chat new message modal
  def friends_list
    friends = current_user.all_friends.map do |f|
      {
        id: f.id,
        name: f.name,
        avatar: f.avatar.attached? ? url_for(f.avatar) : nil,
        online: f.online
      }
    end
    render json: friends
  end

  # Live search endpoint — returns JSON for header dropdown
  def search
    query = params[:q].to_s.strip
    if query.length < 2
      render json: [] and return
    end

    users = User.where.not(id: current_user.id)
                .where("name ILIKE :q OR email ILIKE :q", q: "%#{query}%")
                .order(:name)
                .limit(8)

    results = users.map do |u|
      # Friendship status
      status = if current_user.friends_with?(u)
                 "friends"
               elsif current_user.sent_friend_requests.exists?(friend_id: u.id)
                 "request_sent"
               elsif current_user.pending_friend_requests.exists?(user_id: u.id)
                 "request_received"
               else
                 "none"
               end

      # Find friendship id for accept/reject/unfriend
      friendship = current_user.friendships.find_by(friend_id: u.id) ||
                   u.friendships.find_by(friend_id: current_user.id)

      {
        id: u.id,
        name: u.name,
        email: u.email,
        avatar: u.avatar.attached? ? url_for(u.avatar) : nil,
        online: u.online,
        friendship_status: status,
        friendship_id: friendship&.id,
        profile_url: profile_path(u),
        mutual_friends_count: (current_user.all_friends & u.all_friends).count
      }
    end

    render json: results
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
