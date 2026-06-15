class ProfileHighlightsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_highlight, only: [:update, :destroy, :add_story, :remove_story]

  # GET /profile_highlights (JSON — for profile page)
  def index
    @user       = User.find(params[:user_id])
    @highlights = @user.profile_highlights.ordered.includes(stories: :media_attachment)
    render json: @highlights.map { |h| highlight_json(h) }
  end

  # POST /profile_highlights
  def create
    @highlight = current_user.profile_highlights.build(highlight_params)
    if @highlight.save
      render json: { success: true, highlight: highlight_json(@highlight) }, status: :created
    else
      render json: { errors: @highlight.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /profile_highlights/:id
  def update
    authorize_highlight!
    if @highlight.update(highlight_params)
      render json: { success: true, highlight: highlight_json(@highlight) }
    else
      render json: { errors: @highlight.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /profile_highlights/:id
  def destroy
    authorize_highlight!
    @highlight.destroy
    render json: { success: true }
  end

  # POST /profile_highlights/:id/add_story
  def add_story
    authorize_highlight!
    story = current_user.stories.find(params[:story_id])
    HighlightStory.find_or_create_by!(profile_highlight: @highlight, story: story)
    render json: { success: true, highlight: highlight_json(@highlight) }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Story not found' }, status: :not_found
  end

  # DELETE /profile_highlights/:id/remove_story
  def remove_story
    authorize_highlight!
    HighlightStory.find_by!(profile_highlight: @highlight, story_id: params[:story_id]).destroy
    render json: { success: true }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Not found' }, status: :not_found
  end

  private

  def set_highlight
    @highlight = ProfileHighlight.find(params[:id])
  end

  def authorize_highlight!
    render json: { error: 'Forbidden' }, status: :forbidden unless @highlight.user == current_user
  end

  def highlight_params
    params.require(:profile_highlight).permit(:name, :emoji, :position)
  end

  def highlight_json(h)
    cover = begin
      story = h.stories.order('highlight_stories.position ASC, stories.created_at DESC').first
      story&.media&.attached? ? rails_blob_path(story.media, only_path: true) : nil
    rescue
      nil
    end

    {
      id:       h.id,
      name:     h.name,
      emoji:    h.emoji,
      position: h.position,
      cover:    cover,
      stories_count: h.stories.count
    }
  end
end
