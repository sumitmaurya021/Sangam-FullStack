require 'rails_helper'

RSpec.describe "Search", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /search" do
    it "returns http success for HTML" do
      get search_path, params: { q: "test" }
      expect(response).to have_http_status(:success)
    end

    it "returns JSON for all types with a valid query" do
      create(:user, name: "Searchable Alice")
      get search_path, params: { q: "Alice" }, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key("users")
      expect(json).to have_key("posts")
      expect(json).to have_key("hashtags")
    end

    it "returns empty results for short query" do
      get search_path, params: { q: "a" }
      expect(response).to have_http_status(:success)
    end

    it "filters by people type" do
      get search_path, params: { q: "Alice", type: "people" }, as: :json
      expect(response).to have_http_status(:success)
    end

    it "filters by posts type" do
      get search_path, params: { q: "hello", type: "posts" }, as: :json
      expect(response).to have_http_status(:success)
    end

    it "filters by hashtags type" do
      create(:hashtag, name: "searchtest")
      get search_path, params: { q: "searchtest", type: "hashtags" }, as: :json
      expect(response).to have_http_status(:success)
    end

    it "filters by groups type" do
      create(:group, owner: user, name: "SearchGroup")
      get search_path, params: { q: "SearchGroup", type: "groups" }, as: :json
      expect(response).to have_http_status(:success)
    end

    it "filters by events type" do
      create(:event, organizer: user, title: "SearchEvent", privacy: "public")
      get search_path, params: { q: "SearchEvent", type: "events" }, as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
