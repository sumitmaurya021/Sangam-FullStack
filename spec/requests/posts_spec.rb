require 'rails_helper'

RSpec.describe 'Posts API & Web Requests', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:user_post) { create(:post, user: user, content: 'Original Post Content', visibility: 'public') }

  before do
    sign_in user
  end

  describe 'GET /posts (index)' do
    it 'renders posts feed successfully' do
      get posts_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'GET /posts/:id (show)' do
    it 'renders single post page' do
      get post_path(user_post), headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /posts (create)' do
    context 'with valid parameters' do
      it 'creates a new post and redirects' do
        expect {
          post posts_path, params: { post: { content: 'New post content', visibility: 'public' } }
        }.to change(Post, :count).by(1)

        expect(response).to redirect_to(posts_path)
      end
    end

    context 'with invalid parameters' do
      it 'does not create post and re-renders or responds with unprocessable_entity' do
        expect {
          post posts_path, params: { post: { content: '', visibility: 'public' } }
        }.not_to change(Post, :count)

        expect(response).to have_http_status(:unprocessable_entity).or redirect_to(posts_path)
      end
    end
  end

  describe 'PATCH /posts/:id (update)' do
    context 'when owner updates post' do
      it 'updates content successfully' do
        patch post_path(user_post), params: { post: { content: 'Updated Post Content' } }
        expect(user_post.reload.content).to eq('Updated Post Content')
      end
    end

    context 'when non-owner tries to update post' do
      before { sign_in other_user }

      it 'prevents unauthorized updates' do
        patch post_path(user_post), params: { post: { content: 'Hacked Content' } }
        expect(user_post.reload.content).not_to eq('Hacked Content')
      end
    end
  end

  describe 'DELETE /posts/:id (destroy)' do
    it 'deletes post when authorized' do
      expect {
        delete post_path(user_post)
      }.to change(Post, :count).by(-1)
    end

    it 'prevents non-owners from deleting post' do
      sign_in other_user
      expect {
        delete post_path(user_post)
      }.not_to change(Post, :count)
    end
  end

  describe 'POST /posts/:id/like' do
    it 'toggles like on post' do
      expect {
        post like_post_path(user_post), headers: { 'ACCEPT' => 'application/json' }
      }.to change(Like, :count).by(1)

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'POST /posts/:id/bookmark' do
    it 'creates bookmark for post' do
      expect {
        post bookmark_post_path(user_post), params: { post_id: user_post.id }, headers: { 'ACCEPT' => 'application/json' }
      }.to change(Bookmark, :count).by(1)
    end
  end
end
