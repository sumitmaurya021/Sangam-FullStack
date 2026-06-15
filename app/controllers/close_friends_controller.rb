class CloseFriendsController < ApplicationController
  before_action :authenticate_user!

  # GET /close_friends (JSON list for current user)
  def index
    @close_friends = current_user.close_friends_list.includes(:avatar_attachment)
    render json: @close_friends.map { |u|
      {
        id:     u.id,
        name:   u.name,
        avatar: u.avatar.attached? ? rails_blob_path(u.avatar, only_path: true) : nil
      }
    }
  end

  # POST /close_friends/:user_id   — add to close friends
  def create
    user = User.find(params[:user_id])
    current_user.close_friend_records.find_or_create_by!(close_friend: user)
    render json: { success: true, close_friend: true }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # DELETE /close_friends/:user_id — remove from close friends
  def destroy
    user = User.find(params[:user_id])
    current_user.close_friend_records.find_by(close_friend: user)&.destroy
    render json: { success: true, close_friend: false }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end
end
