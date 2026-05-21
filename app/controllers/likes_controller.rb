class LikesController < ApplicationController
  before_action :set_post

  def create
    @like = @post.likes.find_or_initialize_by(user: current_user)
    @like.reaction_type = params[:reaction_type] || 'like'
    
    if @like.save
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
        format.json { render json: { success: true, reaction: @like.reaction_type } }
      end
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not react to post.')
    end
  end

  def destroy
    @like = @post.likes.find_by(user: current_user)
    
    if @like&.destroy
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
        format.json { render json: { success: true } }
      end
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not remove reaction.')
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end
end
