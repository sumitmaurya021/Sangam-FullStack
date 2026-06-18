class CommentsController < ApplicationController
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user

    # Instagram-style flat replies: always attach to root-level comment
    if @comment.parent_id.present?
      parent = Comment.find_by(id: @comment.parent_id)
      if parent
        # If replying to a reply, re-parent to the root comment
        if parent.parent_id.present?
          @comment.parent_id = parent.parent_id
        end
        # Track who this reply is directed at (for @mention)
        @comment.replied_to_user_id = parent.user_id
      end
    end

    if @comment.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not add comment.')
    end
  end

  def destroy
    @comment = @post.comments.find(params[:id])

    if @comment.user == current_user && @comment.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not delete comment.')
    end
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def comment_params
    params.require(:comment).permit(:content, :parent_id, :replied_to_user_id, :attachment)
  end
end
