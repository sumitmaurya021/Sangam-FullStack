# Handles Story Poll votes & Q&A replies
class StoryInteractionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story

  # POST /stories/:story_id/poll_vote
  def poll_vote
    unless @story.has_poll?
      return render json: { error: 'Story has no poll' }, status: :unprocessable_entity
    end

    if @story.poll_voted_by?(current_user)
      return render json: { error: 'Already voted', voted: true }, status: :unprocessable_entity
    end

    option = params[:option].to_s.downcase
    unless %w[a b].include?(option)
      return render json: { error: 'Invalid option' }, status: :unprocessable_entity
    end

    vote = @story.story_poll_votes.create!(user: current_user, option: option)

    render json: {
      success: true,
      option:  vote.option,
      votes_a: @story.reload.poll_votes_a,
      votes_b: @story.reload.poll_votes_b
    }
  end

  # POST /stories/:story_id/qa_reply
  def qa_reply
    unless @story.has_qa?
      return render json: { error: 'Story has no Q&A' }, status: :unprocessable_entity
    end

    reply = @story.story_qa_replies.build(user: current_user, answer: params[:answer].to_s.strip)

    if reply.save
      # Notify story owner
      if @story.user != current_user
        Notification.create!(
          recipient: @story.user,
          actor:     current_user,
          notifiable: @story,
          notification_type: 'story_qa_reply',
          message: "#{current_user.name} replied to your Q&A"
        )
      end
      render json: { success: true, answer: reply.answer }
    else
      render json: { errors: reply.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /stories/:story_id/qa_replies (owner only)
  def qa_replies
    unless @story.user == current_user
      return render json: { error: 'Forbidden' }, status: :forbidden
    end

    replies = @story.story_qa_replies.includes(:user).order(created_at: :desc)
    render json: replies.map { |r|
      {
        id:     r.id,
        answer: r.answer,
        user:   { id: r.user.id, name: r.user.name }
      }
    }
  end

  private

  def set_story
    @story = Story.find(params[:story_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Story not found' }, status: :not_found
  end
end
