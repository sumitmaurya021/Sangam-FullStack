require 'rails_helper'

RSpec.describe "Shares", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  
  before { sign_in user }

  describe "POST /posts/:id/share" do
    it "creates a share" do
      expect {
        post share_post_path(post_record)
      }.to change(Share, :count).by(1)
    end
    
    it "associates share with user and post" do
      post share_post_path(post_record)
      share = Share.last
      expect(share.user).to eq(user)
      expect(share.post).to eq(post_record)
    end
    
    it "redirects back" do
      post share_post_path(post_record)
      expect(response).to have_http_status(:redirect)
    end
    
    it "does not allow duplicate shares of same post" do
      Share.create!(user: user, post: post_record)
      expect {
        post share_post_path(post_record)
      }.not_to change(Share, :count)
    end
  end
end
