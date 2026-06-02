class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy, :respond_to_event]
  before_action :authorize_organizer!, only: [:edit, :update, :destroy]

  def index
    @upcoming_events = Event.upcoming
                            .where(privacy: 'public')
                            .or(Event.upcoming.where(organizer_id: current_user.id))
                            .includes(:organizer)
                            .page(params[:page]).per(12)

    @my_events = Event.upcoming
                      .joins(:event_responses)
                      .where(event_responses: { user_id: current_user.id, response: 'going' })
                      .includes(:organizer)
                      .limit(5)
  end

  def show
    @going_users      = @event.going_users.limit(8)
    @interested_users = @event.interested_users.limit(8)
    @user_response    = @event.user_response(current_user)
  end

  def new
    @event = Event.new
  end

  def create
    @event = Event.new(event_params.merge(organizer: current_user))
    if @event.save
      redirect_to @event, notice: 'Event created!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @event.update(event_params)
      redirect_to @event, notice: 'Event updated!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @event.destroy
    redirect_to events_path, notice: 'Event deleted.'
  end

  # POST /events/:id/respond
  def respond_to_event
    response_type = params[:response]
    unless EventResponse::RESPONSES.include?(response_type)
      return render json: { error: 'Invalid response' }, status: :unprocessable_entity
    end

    event_response = @event.event_responses.find_or_initialize_by(user: current_user)
    event_response.response = response_type
    event_response.save!

    render json: {
      response:         response_type,
      going_count:      @event.reload.going_count,
      interested_count: @event.interested_count
    }
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def authorize_organizer!
    redirect_to events_path, alert: 'Not authorized.' unless @event.organizer == current_user
  end

  def event_params
    params.require(:event).permit(:title, :description, :location, :privacy, :starts_at, :ends_at, :cover_photo)
  end
end
