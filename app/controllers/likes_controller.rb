class LikesController < ApplicationController
  before_action :set_post

  def create
    @like = @post.likes.build(user: current_user)
    
    if @like.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not like post.')
    end
  end

  def destroy
    @like = @post.likes.find_by(user: current_user)
    
    if @like&.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
      end
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not unlike post.')
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end
end
