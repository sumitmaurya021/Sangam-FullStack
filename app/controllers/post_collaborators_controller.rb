class PostCollaboratorsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_post

  # POST /posts/:post_id/collaborators  — invite user
  def create
    user = User.find(params[:user_id])

    if user == current_user
      return render json: { error: "Can't collaborate with yourself" }, status: :unprocessable_entity
    end

    collab = @post.post_collaborators.find_or_initialize_by(user: user)
    if collab.new_record? && collab.save
      # Notify the invited user
      Notification.create!(
        recipient: user,
        actor: current_user,
        notifiable: @post,
        notification_type: 'collab_invite',
        message: "#{current_user.name} invited you to collaborate on a post"
      )
      render json: { success: true, status: 'pending' }, status: :created
    else
      render json: { error: 'Already invited or collaborating' }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  # PATCH /posts/:post_id/collaborators/:id/accept
  def accept
    collab = @post.post_collaborators.find(params[:id])
    unless collab.user == current_user
      return render json: { error: 'Forbidden' }, status: :forbidden
    end

    collab.accept!
    # Notify post owner
    Notification.create!(
      recipient: @post.user,
      actor: current_user,
      notifiable: @post,
      notification_type: 'collab_accepted',
      message: "#{current_user.name} accepted your collaboration invite"
    )
    render json: { success: true, status: 'accepted' }
  end

  # PATCH /posts/:post_id/collaborators/:id/reject
  def reject
    collab = @post.post_collaborators.find(params[:id])
    unless collab.user == current_user
      return render json: { error: 'Forbidden' }, status: :forbidden
    end

    collab.reject!
    render json: { success: true, status: 'rejected' }
  end

  # DELETE /posts/:post_id/collaborators/:id
  def destroy
    collab = @post.post_collaborators.find(params[:id])
    unless collab.user == current_user || @post.user == current_user
      return render json: { error: 'Forbidden' }, status: :forbidden
    end

    collab.destroy
    render json: { success: true }
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Post not found' }, status: :not_found
  end
end
