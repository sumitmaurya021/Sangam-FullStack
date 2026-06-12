class PollsController < ApplicationController
  before_action :set_poll, only: [:vote]

  # POST /polls/:id/vote
  def vote
    if @poll.voted_by?(current_user)
      respond_with_error('You have already voted in this poll.')
      return
    end

    unless @poll.active?
      respond_with_error('This poll has ended.')
      return
    end

    option = @poll.poll_options.find_by(id: params[:poll_option_id])
    unless option
      respond_with_error('Invalid option.')
      return
    end

    if @poll.vote_for!(current_user, option)
      respond_to do |format|
        format.turbo_stream   # renders vote.turbo_stream.erb
        format.json { render json: poll_results_json(@poll.reload) }
        format.html { redirect_back fallback_location: root_path }
      end
    else
      respond_with_error('Could not record your vote. Please try again.')
    end
  end

  private

  def set_poll
    @poll = Poll.includes(:poll_options).find(params[:id])
  end

  def respond_with_error(message)
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "poll-#{@poll.id}",
          partial: 'polls/poll',
          locals:  { poll: @poll }
        )
      end
      format.json { render json: { error: message }, status: :unprocessable_entity }
      format.html { redirect_back fallback_location: root_path, alert: message }
    end
  end

  def poll_results_json(poll)
    {
      success:     true,
      total_votes: poll.total_votes,
      expired:     !poll.active?,
      options:     poll.poll_options.map { |opt|
        {
          id:          opt.id,
          body:        opt.body,
          votes_count: opt.votes_count,
          percentage:  opt.percentage
        }
      }
    }
  end
end
