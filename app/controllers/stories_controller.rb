class StoriesController < ApplicationController
  before_action :set_story, only: [:show, :destroy, :view]
  before_action :authorize_story!, only: [:destroy]

  def index
    friend_ids = current_user.all_friends.pluck(:id) + [current_user.id]
    @stories_by_user = Story.active
                            .where(user_id: friend_ids)
                            .includes(:user)
                            .order(created_at: :desc)
                            .group_by(&:user)
                            .sort_by { |user, stories|
                              [user == current_user ? 0 : 1, -stories.first.created_at.to_i]
                            }
    render json: story_feed_json if request.format.json?
  end

  def show
    @story.mark_viewed_by!(current_user)
    respond_to do |format|
      format.html
      format.json { render json: story_json(@story) }
    end
  end

  def create
    @story = current_user.stories.build(story_params)

    if @story.save
      respond_to do |format|
        format.html { redirect_to posts_path, notice: 'Story posted!' }
        format.json { render json: story_json(@story), status: :created }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { redirect_to posts_path, alert: @story.errors.full_messages.join(', ') }
        format.json { render json: { errors: @story.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # GET /posts/:id/share_to_story_modal — serves modal HTML
  # Used as fallback for direct navigation; primary path is inline rendering in post card.
  def share_to_story_modal
    @post = Post.find(params[:id])
    render partial: 'stories/share_to_story_modal', locals: { post: @post }
  end

  # POST /posts/:id/share_to_story
  def share_to_story
    @post = Post.find(params[:id])

    if @post.visibility == 'private' && @post.user != current_user
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "share_to_story_modal_#{@post.id}",
            partial: 'stories/share_to_story_result',
            locals: { success: false, message: "You can't share a private post.", post: @post }
          )
        end
        format.html { redirect_back fallback_location: root_path, alert: "You can't share a private post." }
        format.json { render json: { error: "Can't share private post" }, status: :forbidden }
      end
      return
    end

    @story = current_user.stories.build(
      story_type:       'shared_post',
      shared_post:      @post,
      is_shared_post:   true,
      caption:          params[:caption].presence,
      background_color: params[:background_color].presence || '#1a1a2e',
      text_color:       '#ffffff'
    )

    respond_to do |format|
      if @story.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "share_to_story_modal_#{@post.id}",
            partial: 'stories/share_to_story_result',
            locals: { success: true, message: 'Added to your story!', post: @post }
          )
        end
        format.html { redirect_back fallback_location: root_path, notice: 'Added to your story!' }
        format.json { render json: { success: true, story: story_json(@story) }, status: :created }
      else
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "share_to_story_modal_#{@post.id}",
            partial: 'stories/share_to_story_result',
            locals: { success: false, message: @story.errors.full_messages.join(', '), post: @post }
          )
        end
        format.html { redirect_back fallback_location: root_path, alert: @story.errors.full_messages.join(', ') }
        format.json { render json: { errors: @story.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @story.destroy
    respond_to do |format|
      format.html { redirect_to posts_path, notice: 'Story deleted.' }
      format.json { render json: { success: true } }
      format.turbo_stream
    end
  end

  def view
    @story.mark_viewed_by!(current_user)
    render json: { views_count: @story.views_count }
  end

  # GET /stories/active — JSON feed for header stories bar
  def active
    friend_ids = current_user.all_friends.pluck(:id) + [current_user.id]
    stories = Story.active
                   .where(user_id: friend_ids)
                   .includes(:user, :shared_post)
                   .order(created_at: :desc)
                   .group_by(&:user)

    render json: stories.map { |user, user_stories|
      {
        user: {
          id:     user.id,
          name:   user.name,
          avatar: user.avatar.attached? ? url_for(user.avatar) : nil
        },
        stories: user_stories.map { |s| story_json(s) },
        all_viewed: user_stories.all? { |s| s.viewed_by?(current_user) }
      }
    }
  end

  private

  def set_story
    @story = Story.find(params[:id])
  end

  def authorize_story!
    redirect_to posts_path, alert: 'Not authorized.' unless @story.user == current_user
  end

  def story_params
    params.require(:story).permit(:story_type, :caption, :background_color, :text_color, :media)
  end

  def story_json(story)
    base = {
      id:               story.id,
      story_type:       story.story_type,
      caption:          story.caption,
      background_color: story.background_color,
      text_color:       story.text_color,
      views_count:      story.views_count,
      expires_at:       story.expires_at.iso8601,
      viewed:           story.viewed_by?(current_user),
      active:           story.active?,
      is_shared_post:   story.is_shared_post?,
      media_url:        story.media.attached? ? url_for(story.media) : nil,
      created_at:       story.created_at.iso8601,
      user: {
        id:     story.user.id,
        name:   story.user.name,
        avatar: story.user.avatar.attached? ? url_for(story.user.avatar) : nil
      }
    }

    # Include shared post snapshot for client-side rendering
    if story.is_shared_post? && story.shared_post.present?
      post = story.shared_post
      base[:shared_post] = {
        id:        post.id,
        content:   post.content.to_s.truncate(200),
        image_url: begin
                     if post.images.any? && post.images.first.attached?
                       url_for(post.images.first)
                     elsif post.image.attached?
                       url_for(post.image)
                     end
                   rescue
                     nil
                   end,
        author: {
          id:     post.user.id,
          name:   post.user.name,
          avatar: post.user.avatar.attached? ? url_for(post.user.avatar) : nil
        }
      }
    end

    base
  end
end
