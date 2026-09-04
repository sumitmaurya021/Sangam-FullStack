require 'rails_helper'

RSpec.describe "ReelComments", type: :request do
  let(:user) { create(:user) }
  let(:reel) { create(:reel, user: user) }

  before { sign_in user }

  describe "GET /reels/:reel_id/reel_comments" do
    it "returns JSON list of comments" do
      create(:reel_comment, reel: reel, user: user)
      get reel_reel_comments_path(reel), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['comments']).to be_an(Array)
    end
  end

  describe "POST /reels/:reel_id/reel_comments" do
    it "creates a reel comment" do
      expect {
        post reel_reel_comments_path(reel),
          params: { reel_comment: { content: 'Great reel!' } },
          as: :json
      }.to change(ReelComment, :count).by(1)

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "rejects empty content" do
      expect {
        post reel_reel_comments_path(reel),
          params: { reel_comment: { content: '' } },
          as: :json
      }.not_to change(ReelComment, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /reels/:reel_id/reel_comments/:id" do
    let!(:comment) { create(:reel_comment, reel: reel, user: user) }

    it "deletes the comment when owner" do
      expect {
        delete reel_reel_comment_path(reel, comment), as: :json
      }.to change(ReelComment, :count).by(-1)
      expect(response).to have_http_status(:success)
    end

    it "prevents non-owner from deleting" do
      other_user = create(:user)
      sign_in other_user
      delete reel_reel_comment_path(reel, comment), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
