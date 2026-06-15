class FundraisersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_fundraiser, only: [:show, :donate]

  # GET /fundraisers/:id
  def show
    @post = @fundraiser.post
    render json: fundraiser_json(@fundraiser)
  end

  # POST /fundraisers/:id/donate
  def donate
    amount = params[:amount].to_f
    if amount <= 0
      return render json: { error: 'Invalid amount' }, status: :unprocessable_entity
    end

    @fundraiser.increment!(:raised_amount, amount)

    # Notify fundraiser creator
    if @fundraiser.post.user != current_user
      Notification.create!(
        recipient:         @fundraiser.post.user,
        actor:             current_user,
        notifiable:        @fundraiser,
        notification_type: 'fundraiser_donation',
        message:           "#{current_user.name} donated $#{'%.2f' % amount} to your fundraiser"
      )
    end

    render json: {
      success:        true,
      raised_amount:  @fundraiser.raised_amount,
      percentage:     @fundraiser.percentage,
      completed:      @fundraiser.completed?
    }
  end

  private

  def set_fundraiser
    @fundraiser = Fundraiser.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Not found' }, status: :not_found
  end

  def fundraiser_json(f)
    {
      id:             f.id,
      title:          f.title,
      description:    f.description,
      goal_amount:    f.goal_amount,
      raised_amount:  f.raised_amount,
      percentage:     f.percentage,
      currency:       f.currency,
      status:         f.status,
      days_remaining: f.days_remaining,
      completed:      f.completed?
    }
  end
end
