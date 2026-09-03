require 'rails_helper'

RSpec.describe "Reels", type: :request do
  let(:user) { create(:user) }
  let!(:reel) { create(:reel, user: user) }

  before { sign_in user }

  describe "GET /reels" do
    it "returns http success" do
      get reels_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON list of reels" do
      get reels_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('reels')
    end
  end

  describe "POST /reels" do
    it "creates a reel with valid params" do
      expect {
        post reels_path, params: { reel: { caption: 'My Cool Reel' } }
      }.to change(Reel, :count).by(1)
      expect(response).to redirect_to(reels_path)
    end
  end

  describe "DELETE /reels/:id" do
    it "deletes the reel when owner" do
      expect {
        delete reel_path(reel)
      }.to change(Reel, :count).by(-1)
      expect(response).to redirect_to(reels_path)
    end

    it "prevents non-owner from deleting" do
      other_user = create(:user)
      sign_in other_user
      delete reel_path(reel)
      expect(response).to redirect_to(reels_path)
      expect(Reel.find_by(id: reel.id)).to be_present
    end
  end

  describe "POST /reels/:id/like" do
    it "likes a reel" do
      post like_reel_path(reel), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe "DELETE /reels/:id/unlike" do
    before { create(:reel_like, user: user, reel: reel) }

    it "unlikes a reel" do
      delete unlike_reel_path(reel), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe "POST /reels/:id/view" do
    it "increments view count" do
      post view_reel_path(reel), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end
end
