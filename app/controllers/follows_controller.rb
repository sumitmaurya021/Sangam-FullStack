class FollowsController < ApplicationController
  before_action :set_followee

  # POST /follows?followee_id=:id
  def create
    if current_user == @followee
      return redirect_back(fallback_location: root_path, alert: "You can't follow yourself.")
    end

    @follow = current_user.active_follows.build(followee: @followee)

    respond_to do |format|
      if @follow.save
        format.html { redirect_back(fallback_location: profile_path(@followee)) }
        format.turbo_stream
        format.json { render json: { following: true, followers_count: @followee.reload.followers_count } }
      else
        format.html { redirect_back(fallback_location: root_path, alert: 'Could not follow user.') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("follow_btn_#{@followee.id}", partial: 'follows/button', locals: { user: @followee }) }
        format.json { render json: { error: @follow.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /follows/:id  (id = followee_id for simplicity via nested route)
  def destroy
    @follow = current_user.active_follows.find_by!(followee: @followee)

    respond_to do |format|
      if @follow.destroy
        format.html { redirect_back(fallback_location: profile_path(@followee)) }
        format.turbo_stream
        format.json { render json: { following: false, followers_count: @followee.reload.followers_count } }
      else
        format.html { redirect_back(fallback_location: root_path, alert: 'Could not unfollow user.') }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("follow_btn_#{@followee.id}", partial: 'follows/button', locals: { user: @followee }) }
        format.json { render json: { error: 'Could not unfollow' }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_followee
    @followee = User.find(params[:followee_id])
  end
end
