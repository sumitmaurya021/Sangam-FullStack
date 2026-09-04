require 'rails_helper'

RSpec.describe "CloseFriends", type: :request do
  let(:user)         { create(:user) }
  let(:other_user)   { create(:user) }

  before { sign_in user }

  describe "GET /close_friends" do
    it "returns JSON list of close friends" do
      get close_friends_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end

  describe "POST /close_friends" do
    it "adds a user to close friends" do
      post close_friends_path, params: { user_id: other_user.id }, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(json['close_friend']).to be true
    end

    it "returns 404 for non-existent user" do
      post close_friends_path, params: { user_id: 999_999 }, as: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /close_friends/:user_id" do
    before { user.close_friend_records.find_or_create_by!(close_friend: other_user) }

    it "removes a user from close friends" do
      delete close_friend_path(other_user.id), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['close_friend']).to be false
    end
  end
end
