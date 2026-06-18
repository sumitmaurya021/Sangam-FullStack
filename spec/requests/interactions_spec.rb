require 'rails_helper'

RSpec.describe "Api::Interactions", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: create(:user)) }

  before do
    sign_in user
  end

  describe "POST /api/interactions" do
    it "logs a valid interaction and returns success" do
      expect {
        post "/api/interactions", params: {
          post_id: post_record.id,
          interaction_type: 'dwell'
        }, as: :json
      }.to change(UserInteraction, :count).by(1)

      expect(response).to have_http_status(:success)
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to eq(true)
    end

    it "returns error for invalid interaction type" do
      post "/api/interactions", params: {
        post_id: post_record.id,
        interaction_type: 'invalid_type'
      }, as: :json

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
