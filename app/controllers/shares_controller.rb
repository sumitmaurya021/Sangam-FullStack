class SharesController < ApplicationController
  before_action :set_post

  def create
    @share = @post.shares.build(user: current_user)
    
    if @share.save
      redirect_back(fallback_location: posts_path, notice: 'Post shared successfully!')
    else
      redirect_back(fallback_location: posts_path, alert: 'Could not share post.')
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
  end
end
