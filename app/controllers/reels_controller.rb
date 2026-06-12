class ReelsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_reel, only: [:destroy, :like, :unlike, :view]

  REELS_PER_PAGE = 10

  def index
    @reels = Reel.includes(:user, :reel_likes, :reel_comments)
                 .order(created_at: :desc)
                 .page(params[:page])
                 .per(REELS_PER_PAGE)
    @reel = Reel.new

    respond_to do |format|
      format.html
      format.json do
        render json: {
          reels: @reels.map { |r| reel_json(r) },
          next_page: @reels.next_page,
          total_pages: @reels.total_pages
        }
      end
    end
  end

  def create
    @reel = current_user.reels.build(reel_params)

    if @reel.save
      respond_to do |format|
        format.html { redirect_to reels_path, notice: 'Reel uploaded successfully!' }
        format.json { render json: { success: true, reel_id: @reel.id } }
      end
    else
      respond_to do |format|
        format.html do
          @reels = Reel.includes(:user, :reel_likes, :reel_comments)
                       .order(created_at: :desc)
                       .page(1)
                       .per(REELS_PER_PAGE)
          render :index, status: :unprocessable_entity
        end
        format.json { render json: { errors: @reel.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    if @reel.user == current_user
      @reel.destroy
      respond_to do |format|
        format.html { redirect_to reels_path, notice: 'Reel deleted.' }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_to reels_path, alert: 'You can only delete your own reels.' }
        format.json { render json: { error: 'Unauthorized' }, status: :forbidden }
      end
    end
  end

  def like
    @like = @reel.reel_likes.find_or_initialize_by(user: current_user)

    if @like.save
      render json: {
        success: true,
        likes_count: @reel.reload.likes_count
      }
    else
      render json: { error: 'Could not like' }, status: :unprocessable_entity
    end
  end

  def unlike
    @like = @reel.reel_likes.find_by(user: current_user)
    if @like&.destroy
      render json: { success: true, likes_count: @reel.reload.likes_count }
    else
      render json: { error: 'Not found' }, status: :not_found
    end
  end

  def view
    reel = Reel.find(params[:id])
    reel.increment_views!
    render json: { success: true, views_count: reel.views_count }
  end

  private

  def set_reel
    @reel = Reel.find(params[:id])
  end

  def reel_params
    if params[:reel].present?
      params.require(:reel).permit(:caption, :video, :thumbnail,
                                   :music_title, :music_artist, :music_preview_url, :hashtags)
    else
      ActionController::Parameters.new(
        caption:           params[:caption],
        video:             params[:video],
        thumbnail:         params[:thumbnail],
        music_title:       params[:music_title],
        music_artist:      params[:music_artist],
        music_preview_url: params[:music_preview_url],
        hashtags:          params[:hashtags]
      ).permit(:caption, :video, :thumbnail, :music_title, :music_artist, :music_preview_url, :hashtags)
    end
  end

  def reel_json(reel)
    {
      id: reel.id,
      caption: reel.caption,
      likes_count: reel.likes_count,
      comments_count: reel.comments_count,
      views_count: reel.views_count,
      user: {
        id: reel.user.id,
        name: reel.user.name,
        avatar: reel.user.avatar.attached? ? url_for(reel.user.avatar) : nil
      },
      video_url: reel.video.attached? ? url_for(reel.video) : nil,
      thumbnail_url: reel.thumbnail.attached? ? url_for(reel.thumbnail) : nil,
      music_title: reel.music_title,
      music_artist: reel.music_artist,
      hashtags: reel.hashtag_list,
      created_at: reel.created_at.iso8601,
      liked_by_current_user:      reel.liked_by?(current_user),
      bookmarked_by_current_user: reel.bookmarked_by?(current_user)
    }
  end
end
