require 'rails_helper'

RSpec.describe "Settings", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "PATCH /settings/dark_mode" do
    it "toggles dark mode on" do
      user.update_column(:dark_mode, false)
      patch toggle_dark_mode_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['dark_mode']).to be true
    end

    it "toggles dark mode off" do
      user.update_column(:dark_mode, true)
      patch toggle_dark_mode_path, as: :json
      json = JSON.parse(response.body)
      expect(json['dark_mode']).to be false
    end

    it "requires authentication" do
      sign_out user
      patch toggle_dark_mode_path, as: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
