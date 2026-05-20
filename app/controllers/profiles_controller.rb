class ProfilesController < ApplicationController
  before_action :set_user

  def show
    @posts = @user.posts.includes(:likes, :comments, :shares).order(created_at: :desc)
    @friends_count = @user.all_friends.count
    @posts_count = @user.posts.count
  end

  def friends
    @friends = @user.all_friends
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
