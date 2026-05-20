require 'rails_helper'

RSpec.describe "Shares", type: :request do
  describe "GET /create" do
    it "returns http success" do
      get "/shares/create"
      expect(response).to have_http_status(:success)
    end
  end

end
