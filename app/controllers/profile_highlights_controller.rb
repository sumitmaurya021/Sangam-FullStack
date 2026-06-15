class ProfileHighlightsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_highlight, only: [:update, :destroy, :add_story, :remove_story, :stories]

  # GET /profile_highlights (JSON — for profile page)
  def index
    @user       = User.find(params[:user_id])
    @highlights = @user.profile_highlights.ordered
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

  # GET /profile_highlights/:id/stories
  # Returns JSON list of stories in this highlight for the story viewer
  def stories
    story_list = @highlight.stories
                            .order('highlight_stories.position ASC, stories.created_at DESC')
                            .includes(:user, :media_attachment)

    respond_to do |format|
      format.json do
        render json: {
          highlight: {
            id:   @highlight.id,
            name: @highlight.name,
            emoji: @highlight.emoji
          },
          stories: story_list.map { |s| story_data(s) }
        }
      end
      format.html do
        # Fallback: redirect to owner's profile — viewer will open client-side
        redirect_to profile_path(@highlight.user),
                    notice: "Opening highlight: #{@highlight.name}"
      end
    end
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
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to root_path, alert: 'Highlight not found.' }
      format.json { render json: { error: 'Not found' }, status: :not_found }
    end
  end

  def authorize_highlight!
    unless @highlight.user == current_user
      render json: { error: 'Forbidden' }, status: :forbidden
    end
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
      id:            h.id,
      name:          h.name,
      emoji:         h.emoji,
      position:      h.position,
      cover:         cover,
      stories_count: h.stories.count,
      stories_url:   stories_profile_highlight_path(h)
    }
  end

  def story_data(story)
    {
      id:               story.id,
      story_type:       story.story_type,
      caption:          story.caption,
      background_color: story.background_color,
      text_color:       story.text_color,
      views_count:      story.views_count,
      expires_at:       story.expires_at.iso8601,
      active:           story.active?,
      archived:         story.archived,
      media_url:        story.media.attached? ? url_for(story.media) : nil,
      poll_question:    story.poll_question,
      poll_option_a:    story.poll_option_a,
      poll_option_b:    story.poll_option_b,
      poll_votes_a:     story.poll_votes_a,
      poll_votes_b:     story.poll_votes_b,
      qa_question:      story.qa_question,
      created_at:       story.created_at.iso8601,
      user: {
        id:     story.user.id,
        name:   story.user.name,
        avatar: story.user.avatar.attached? ? url_for(story.user.avatar) : nil
      }
    }
  end
end
