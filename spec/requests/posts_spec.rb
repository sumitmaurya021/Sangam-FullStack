require 'rails_helper'

RSpec.describe "Posts", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  
  before { sign_in user }

  describe "GET /posts" do
    it "returns http success" do
      get posts_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays posts feed" do
      get posts_path
      expect(response.body).to include('feed-container')
    end
  end

  describe "POST /posts" do
    context "with valid params" do
      it "creates a new post" do
        expect {
          post posts_path, params: { post: { content: "Test post content" } }
        }.to change(Post, :count).by(1)
      end
      
      it "redirects to posts feed" do
        post posts_path, params: { post: { content: "Test post content" } }
        expect(response).to redirect_to(posts_path)
      end
    end
    
    context "with invalid params" do
      it "does not create a post" do
        expect {
          post posts_path, params: { post: { content: "" } }
        }.not_to change(Post, :count)
      end
    end
  end

  describe "DELETE /posts/:id" do
    it "deletes the post" do
      post_to_delete = create(:post, user: user)
      expect {
        delete post_path(post_to_delete)
      }.to change(Post, :count).by(-1)
    end
    
    it "redirects to posts feed" do
      delete post_path(post_record)
      expect(response).to redirect_to(posts_path)
    end
    
    it "does not allow deleting other users' posts" do
      other_user = create(:user)
      other_post = create(:post, user: other_user)
      
      delete post_path(other_post)
      expect(Post.exists?(other_post.id)).to be true
    end
  end
end
