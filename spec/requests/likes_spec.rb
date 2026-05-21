require 'rails_helper'

RSpec.describe "Likes", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  
  before { sign_in user }

  describe "POST /posts/:id/like" do
    it "creates a like" do
      expect {
        post like_post_path(post_record)
      }.to change(Like, :count).by(1)
    end
    
    it "associates like with user and post" do
      post like_post_path(post_record)
      like = Like.last
      expect(like.user).to eq(user)
      expect(like.post).to eq(post_record)
    end
    
    it "redirects back" do
      post like_post_path(post_record)
      expect(response).to have_http_status(:redirect)
    end
    
    it "does not create duplicate likes" do
      Like.create!(user: user, post: post_record)
      expect {
        post like_post_path(post_record)
      }.not_to change(Like, :count)
    end
  end

  describe "DELETE /posts/:id/unlike" do
    let!(:like) { Like.create!(user: user, post: post_record) }
    
    it "deletes the like" do
      expect {
        delete unlike_post_path(post_record)
      }.to change(Like, :count).by(-1)
    end
    
    it "redirects back" do
      delete unlike_post_path(post_record)
      expect(response).to have_http_status(:redirect)
    end
  end
end
