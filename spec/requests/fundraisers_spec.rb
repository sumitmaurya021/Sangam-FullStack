require 'rails_helper'

RSpec.describe "Fundraisers", type: :request do
  let(:user)        { create(:user) }
  let(:post_record) { create(:post, user: user) }
  let!(:fundraiser) do
    create(:fundraiser,
      post: post_record,
      title: 'Help build a school',
      goal_amount: 5000.00,
      raised_amount: 0.00,
      status: 'active'
    )
  end

  before { sign_in user }

  describe "GET /fundraisers/:id" do
    it "returns JSON fundraiser data" do
      get fundraiser_path(fundraiser), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['title']).to eq('Help build a school')
    end
  end

  describe "POST /fundraisers/:id/donate" do
    it "adds donation amount" do
      post donate_fundraiser_path(fundraiser), params: { amount: 100 }, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(fundraiser.reload.raised_amount).to eq(100.0)
    end

    it "rejects zero or negative donation" do
      post donate_fundraiser_path(fundraiser), params: { amount: 0 }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
