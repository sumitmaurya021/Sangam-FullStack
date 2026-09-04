require 'rails_helper'

RSpec.describe "Hashtags", type: :request do
  let(:user) { create(:user) }

  before { sign_in user }

  describe "GET /hashtag/:name" do
    it "returns http success for existing hashtag" do
      hashtag = create(:hashtag, name: 'rails')
      post_record = create(:post, user: user, published: true, visibility: 'public')
      create(:post_hashtag, post: post_record, hashtag: hashtag)

      get hashtag_path(name: 'rails')
      expect(response).to have_http_status(:success)
    end

    it "returns 404 for non-existent hashtag" do
      get hashtag_path(name: 'nonexistent_xyz_tag')
      expect(response).to have_http_status(:not_found).or redirect_to(root_path)
    end
  end

  describe "GET /explore" do
    it "returns http success" do
      get explore_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON trending hashtags" do
      create(:hashtag, name: 'trending')
      get explore_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('hashtags')
    end
  end
end
