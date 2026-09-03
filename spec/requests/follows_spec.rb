require 'rails_helper'

RSpec.describe "Follows", type: :request do
  let(:follower) { create(:user) }
  let(:followee) { create(:user) }

  before { sign_in follower }

  describe "POST /follows" do
    it "creates a follow relationship" do
      expect {
        post follows_path, params: { followee_id: followee.id }, as: :json
      }.to change(Follow, :count).by(1)

      json = JSON.parse(response.body)
      expect(json['following']).to be true
    end

    it "prevents self-follow" do
      post follows_path, params: { followee_id: follower.id }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /follows/:id" do
    before { follower.follow!(followee) }

    it "removes a follow relationship" do
      expect {
        delete follow_path(followee.id), params: { followee_id: followee.id }, as: :json
      }.to change(Follow, :count).by(-1)

      json = JSON.parse(response.body)
      expect(json['following']).to be false
    end
  end
end
