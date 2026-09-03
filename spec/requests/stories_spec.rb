require 'rails_helper'

RSpec.describe "Stories", type: :request do
  let(:user)  { create(:user) }
  let!(:story) { create(:story, user: user, story_type: 'text', expires_at: 24.hours.from_now) }

  before { sign_in user }

  describe "GET /stories" do
    it "returns http success" do
      get stories_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON feed" do
      get stories_path, as: :json
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /stories/:id" do
    it "returns http success" do
      get story_path(story)
      expect(response).to have_http_status(:success)
    end

    it "returns JSON" do
      get story_path(story), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('id')
    end
  end

  describe "POST /stories" do
    it "creates a text story" do
      expect {
        post stories_path, params: {
          story: { story_type: 'text', caption: 'My story text', background_color: '#ff0000' }
        }, as: :json
      }.to change(Story, :count).by(1)

      expect(response).to have_http_status(:created)
    end
  end

  describe "DELETE /stories/:id" do
    it "deletes the story when owner" do
      expect {
        delete story_path(story), as: :json
      }.to change(Story, :count).by(-1)
      expect(response).to have_http_status(:success)
    end

    it "prevents non-owner from deleting" do
      other_user = create(:user)
      sign_in other_user
      delete story_path(story)
      expect(response).to redirect_to(posts_path)
    end
  end

  describe "POST /stories/:id/view" do
    it "marks story as viewed" do
      post view_story_path(story), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('views_count')
    end
  end

  describe "GET /stories/active" do
    it "returns active stories JSON" do
      get active_stories_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end
end
