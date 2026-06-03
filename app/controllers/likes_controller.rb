class LikesController < ApplicationController
  before_action :set_post

  def create
    @like = @post.likes.find_or_initialize_by(user: current_user)
    @like.reaction_type = params[:reaction_type] || 'like'
    
    if @like.save
      @post.reload # Reload to get updated counter_cache
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
        format.json do
          render json: {
            success: true,
            reaction: @like.reaction_type,
            likes_count: @post.likes_count,
            reaction_counts: @post.reaction_counts
          }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path, alert: 'Could not react to post.') }
        format.json { render json: { success: false, errors: @like.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @like = @post.likes.find_by(user: current_user)
    
    if @like&.destroy
      @post.reload # Reload to get updated counter_cache
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path) }
        format.turbo_stream
        format.json do
          render json: {
            success: true,
            likes_count: @post.likes_count,
            reaction_counts: @post.reaction_counts
          }
        end
      end
    else
      respond_to do |format|
        format.html { redirect_back(fallback_location: posts_path, alert: 'Could not remove reaction.') }
        format.json { render json: { success: false }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end
end
