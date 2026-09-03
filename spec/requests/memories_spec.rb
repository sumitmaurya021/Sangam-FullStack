require 'rails_helper'

RSpec.describe "Memories", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /memories" do
    it "returns http success" do
      get memories_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON with memories count" do
      get memories_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('count')
      expect(json).to have_key('memories')
    end
  end

  it "requires authentication" do
    sign_out user
    get memories_path
    expect(response).to redirect_to(new_user_session_path)
  end
end
