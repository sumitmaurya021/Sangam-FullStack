class FriendshipsController < ApplicationController
  before_action :set_friendship, only: [:accept, :reject, :destroy]

  def create
    @friend = User.find(params[:friend_id])
    @friendship = current_user.friendships.build(friend: @friend)
    
    if @friendship.save
      redirect_back(fallback_location: root_path, notice: 'Friend request sent!')
    else
      redirect_back(fallback_location: root_path, alert: 'Could not send friend request.')
    end
  end

  def accept
    if @friendship.friend == current_user && @friendship.accept!
      redirect_back(fallback_location: root_path, notice: 'Friend request accepted!')
    else
      redirect_back(fallback_location: root_path, alert: 'Could not accept friend request.')
    end
  end

  def reject
    if @friendship.friend == current_user && @friendship.reject!
      redirect_back(fallback_location: root_path, notice: 'Friend request rejected.')
    else
      redirect_back(fallback_location: root_path, alert: 'Could not reject friend request.')
    end
  end

  def destroy
    if (@friendship.user == current_user || @friendship.friend == current_user) && @friendship.destroy
      redirect_back(fallback_location: root_path, notice: 'Friendship removed.')
    else
      redirect_back(fallback_location: root_path, alert: 'Could not remove friendship.')
    end
  end

  private

  def set_friendship
    @friendship = Friendship.find(params[:id])
  end
end
