require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }

  before { sign_in user }

  describe "GET /profiles/:id" do
    it "returns http success for own profile" do
      get profile_path(user)
      expect(response).to have_http_status(:success)
    end

    it "returns http success for another user's profile" do
      get profile_path(other_user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profiles/:id/friends" do
    it "returns http success" do
      get friends_profile_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profiles/:id/following" do
    it "returns http success" do
      get following_profile_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profiles/:id/followers" do
    it "returns http success" do
      get followers_profile_path(user)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /profiles/friends_list" do
    it "returns JSON friends list" do
      get friends_list_profiles_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end

  describe "GET /profiles/search" do
    it "returns matching users as JSON" do
      create(:user, name: "SearchableUser")
      get search_profiles_path, params: { q: "Searchable" }, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end

    it "returns empty for short query" do
      get search_profiles_path, params: { q: "a" }, as: :json
      json = JSON.parse(response.body)
      expect(json).to eq([])
    end
  end
end
