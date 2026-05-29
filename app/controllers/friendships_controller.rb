class FriendshipsController < ApplicationController
  before_action :set_friendship, only: [:accept, :reject, :destroy]

  def create
    @friend = User.find(params[:friend_id])
    @friendship = current_user.friendships.build(friend: @friend)

    respond_to do |format|
      if @friendship.save
        format.html { redirect_back(fallback_location: root_path, notice: 'Friend request sent!') }
        format.json { render json: { success: true, friendship_id: @friendship.id, status: 'request_sent' } }
      else
        format.html { redirect_back(fallback_location: root_path, alert: 'Could not send friend request.') }
        format.json { render json: { success: false, errors: @friendship.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def accept
    respond_to do |format|
      if @friendship.friend == current_user && @friendship.accept!
        format.html { redirect_back(fallback_location: root_path, notice: 'Friend request accepted!') }
        format.json { render json: { success: true, status: 'friends' } }
      else
        format.html { redirect_back(fallback_location: root_path, alert: 'Could not accept friend request.') }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  def reject
    respond_to do |format|
      if @friendship.friend == current_user && @friendship.reject!
        format.html { redirect_back(fallback_location: root_path, notice: 'Friend request rejected.') }
        format.json { render json: { success: true } }
      else
        format.html { redirect_back(fallback_location: root_path, alert: 'Could not reject friend request.') }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    respond_to do |format|
      if (@friendship.user == current_user || @friendship.friend == current_user) && @friendship.destroy
        format.html { redirect_back(fallback_location: root_path, notice: 'Friendship removed.') }
        format.json { render json: { success: true } }
      else
        format.html { redirect_back(fallback_location: root_path, alert: 'Could not remove friendship.') }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_friendship
    @friendship = Friendship.find(params[:id])
  end
end
