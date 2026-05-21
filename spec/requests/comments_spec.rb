require 'rails_helper'

RSpec.describe "Comments", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  
  before { sign_in user }

  describe "POST /posts/:post_id/comments" do
    context "with valid params" do
      it "creates a comment" do
        expect {
          post post_comments_path(post_record), params: { comment: { content: "Test comment" } }
        }.to change(Comment, :count).by(1)
      end
      
      it "associates comment with user and post" do
        post post_comments_path(post_record), params: { comment: { content: "Test comment" } }
        comment = Comment.last
        expect(comment.user).to eq(user)
        expect(comment.post).to eq(post_record)
      end
      
      it "redirects back" do
        post post_comments_path(post_record), params: { comment: { content: "Test comment" } }
        expect(response).to have_http_status(:redirect)
      end
    end
    
    context "with invalid params" do
      it "does not create a comment with empty content" do
        expect {
          post post_comments_path(post_record), params: { comment: { content: "" } }
        }.not_to change(Comment, :count)
      end
    end
  end

  describe "DELETE /posts/:post_id/comments/:id" do
    let!(:comment) { Comment.create!(user: user, post: post_record, content: "Test comment") }
    
    it "deletes the comment" do
      expect {
        delete post_comment_path(post_record, comment)
      }.to change(Comment, :count).by(-1)
    end
    
    it "redirects back" do
      delete post_comment_path(post_record, comment)
      expect(response).to have_http_status(:redirect)
    end
    
    it "does not allow deleting other users' comments" do
      other_user = create(:user)
      other_comment = Comment.create!(user: other_user, post: post_record, content: "Other comment")
      
      delete post_comment_path(post_record, other_comment)
      expect(Comment.exists?(other_comment.id)).to be true
    end
  end
end
