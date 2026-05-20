class CommentsController < ApplicationController
  before_action :set_post

  def create
    @comment = @post.comments.build(comment_params)
    @comment.user = current_user
    
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
    params.require(:comment).permit(:content)
  end
end
