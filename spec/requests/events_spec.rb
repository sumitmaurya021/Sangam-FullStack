require 'rails_helper'

RSpec.describe "Events", type: :request do
  let(:user) { create(:user) }
  let!(:event) do
    create(:event,
      organizer: user,
      title: 'Tech Meetup 2026',
      privacy: 'public',
      starts_at: 2.days.from_now,
      ends_at: 2.days.from_now + 2.hours
    )
  end

  before { sign_in user }

  describe "GET /events" do
    it "returns http success" do
      get events_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /events/:id" do
    it "returns http success" do
      get event_path(event)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /events/new" do
    it "returns http success" do
      get new_event_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /events" do
    context "with valid parameters" do
      it "creates an event and redirects" do
        expect {
          post events_path, params: {
            event: {
              title: 'New Community Event',
              description: 'A great event',
              location: 'Online',
              privacy: 'public',
              starts_at: 3.days.from_now,
              ends_at: 3.days.from_now + 1.hour
            }
          }
        }.to change(Event, :count).by(1)
        expect(response).to redirect_to(event_path(Event.last))
      end
    end

    context "with invalid parameters" do
      it "does not create event and re-renders form" do
        expect {
          post events_path, params: { event: { title: '', description: '' } }
        }.not_to change(Event, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /events/:id" do
    it "updates event when organizer" do
      patch event_path(event), params: { event: { title: 'Updated Meetup' } }
      expect(response).to redirect_to(event_path(event))
      expect(event.reload.title).to eq('Updated Meetup')
    end

    it "prevents non-organizer from updating" do
      other_user = create(:user)
      sign_in other_user
      patch event_path(event), params: { event: { title: 'Hacked' } }
      expect(response).to redirect_to(events_path)
    end
  end

  describe "DELETE /events/:id" do
    it "deletes the event" do
      expect {
        delete event_path(event)
      }.to change(Event, :count).by(-1)
      expect(response).to redirect_to(events_path)
    end
  end

  describe "POST /events/:id/respond" do
    it "records a going response" do
      post respond_to_event_event_path(event), params: { response: 'going' },
        as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['response']).to eq('going')
    end

    it "returns error for invalid response type" do
      post respond_to_event_event_path(event), params: { response: 'invalid' },
        as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
