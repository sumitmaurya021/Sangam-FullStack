class HashtagsController < ApplicationController
  def show
    @hashtag = Hashtag.find_by!(name: params[:name].downcase.gsub(/\A#/, ''))
    @posts   = @hashtag.posts
                       .visible_to(current_user)
                       .includes(:user, :likes, :comments)
                       .order(created_at: :desc)
                       .page(params[:page]).per(12)
  end

  def explore
    @trending_hashtags = Hashtag.trending.limit(20)
    @recent_posts      = Post.visible_to(current_user)
                             .includes(:user, :likes, :comments, :hashtags)
                             .order(created_at: :desc)
                             .limit(20)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          hashtags: @trending_hashtags.map { |h| { name: h.name, posts_count: h.posts_count } }
        }
      end
    end
  end
end
