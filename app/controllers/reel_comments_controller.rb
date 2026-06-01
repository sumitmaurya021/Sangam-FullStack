class ReelCommentsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reel

  def index
    @comments = @reel.reel_comments
                     .includes(:user)
                     .root_comments
                     .recent
    render json: { comments: @comments.map { |c| comment_json(c) } }
  end

  def create
    @comment = @reel.reel_comments.build(comment_params)
    @comment.user = current_user

    if @comment.save
      render json: {
        success: true,
        comment: comment_json(@comment)
      }
    else
      render json: { errors: @comment.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @comment = @reel.reel_comments.find(params[:id])

    if @comment.user == current_user
      @comment.destroy
      render json: { success: true }
    else
      render json: { error: 'Unauthorized' }, status: :forbidden
    end
  end

  private

  def set_reel
    @reel = Reel.find(params[:reel_id])
  end

  def comment_params
    params.require(:reel_comment).permit(:content, :parent_id)
  end

  def comment_json(comment)
    {
      id: comment.id,
      content: comment.content,
      parent_id: comment.parent_id,
      created_at: comment.created_at.iso8601,
      user: {
        id: comment.user.id,
        name: comment.user.name,
        avatar: comment.user.avatar.attached? ? url_for(comment.user.avatar) : nil
      }
    }
  end
end
