module Admin
  class DashboardController < ApplicationController
    layout 'admin'
    before_action :authenticate_user!
    before_action :verify_super_admin!
    helper_method :controller_action?

    def index
      # Overall Statistics
      @total_users       = User.count
      @total_posts       = Post.count
      @total_likes       = Like.count
      @total_comments    = Comment.count
      @total_shares      = Share.count
      @total_friendships = Friendship.where(status: 'accepted').count
      @total_reels       = Reel.count
      @total_stories     = Story.count
      @total_groups      = Group.count
      @total_events      = Event.count

      # Recent Activity
      @recent_users = User.order(created_at: :desc).limit(8)
      @recent_posts = Post.includes(:user).order(created_at: :desc).limit(8)

      # Top Users
      @top_posters = User.left_joins(:posts)
                         .group('users.id')
                         .order('COUNT(posts.id) DESC')
                         .limit(8)
                         .select('users.*, COUNT(posts.id) as posts_count')

      @top_likers = User.left_joins(:likes)
                        .group('users.id')
                        .order('COUNT(likes.id) DESC')
                        .limit(8)
                        .select('users.*, COUNT(likes.id) as likes_count')

      @top_commenters = User.left_joins(:comments)
                            .group('users.id')
                            .order('COUNT(comments.id) DESC')
                            .limit(8)
                            .select('users.*, COUNT(comments.id) as comments_count')

      # Growth Statistics (Last 30 days)
      @users_last_30_days  = User.where('created_at >= ?', 30.days.ago).count
      @posts_last_30_days  = Post.where('created_at >= ?', 30.days.ago).count
      @likes_last_30_days  = Like.where('created_at >= ?', 30.days.ago).count
      @comments_last_30_days = Comment.where('created_at >= ?', 30.days.ago).count

      # Chart: last 7 days daily activity using groupdate single query aggregation
      six_days_ago = 6.days.ago.beginning_of_day
      daily_users = User.where('created_at >= ?', six_days_ago).group_by_day(:created_at).count
      daily_posts = Post.where('created_at >= ?', six_days_ago).group_by_day(:created_at).count
      daily_likes = Like.where('created_at >= ?', six_days_ago).group_by_day(:created_at).count

      date_range = (6.days.ago.to_date..Date.today)
      @chart_labels = date_range.map { |d| d.strftime('%b %d') }.to_json
      @chart_users  = date_range.map { |d| daily_users[d] || 0 }.to_json
      @chart_posts  = date_range.map { |d| daily_posts[d] || 0 }.to_json
      @chart_likes  = date_range.map { |d| daily_likes[d] || 0 }.to_json

      # Donut chart data
      @donut_data = [@total_posts, @total_likes, @total_comments, @total_shares].to_json

      # Engagement
      @users_with_posts    = User.joins(:posts).distinct.count
      @users_with_likes    = User.joins(:likes).distinct.count
      @users_with_comments = User.joins(:comments).distinct.count
      @users_with_friends  = User.joins(:friendships).where(friendships: { status: 'accepted' }).distinct.count

      # Averages
      @avg_posts_per_user    = @total_users > 0 ? (@total_posts.to_f / @total_users).round(1) : 0
      @avg_likes_per_post    = @total_posts > 0 ? (@total_likes.to_f / @total_posts).round(1) : 0
      @avg_comments_per_post = @total_posts > 0 ? (@total_comments.to_f / @total_posts).round(1) : 0
    end

    def users
      @users = User.order(created_at: :desc).page(params[:page]).per(20)
    end

    def posts
      @posts = Post.includes(:user).order(created_at: :desc).page(params[:page]).per(20)
    end

    def user_details
      @user = User.find(params[:id])
      @user_posts = @user.posts.count
      @user_likes = @user.likes.count
      @user_comments = @user.comments.count
      @user_shares = @user.shares.count
      @user_friends = @user.all_friends.count
    end

    private

    def verify_super_admin!
      unless current_user.super_admin?
        redirect_to root_path, alert: 'Access denied. Super Admin privileges required.'
      end
    end

    def controller_action?(ctrl, act)
      controller_name == ctrl && action_name == act
    end
  end
end
