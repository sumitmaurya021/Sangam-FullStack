require 'rails_helper'

RSpec.describe 'Security Specifications', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    sign_in user
  end

  describe 'SQL Injection Prevention' do
    it 'handles SQL injection attempt in search params safely' do
      post = create(:post, user: user, content: 'Normal post content')

      expect {
        get search_path, params: { q: "' OR '1'='1" }
      }.not_to raise_error

      expect(response).to have_http_status(:ok)
    end
  end

  describe 'Cross-Site Scripting (XSS) Sanitization' do
    it 'escapes HTML script tags in post content output' do
      xss_content = "<script>alert('XSS')</script>"
      post = create(:post, user: user, content: xss_content)

      get post_path(post), headers: { 'X-Requested-With' => 'XMLHttpRequest' }
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("<script>alert('XSS')</script>")
    end
  end

  describe 'IDOR (Insecure Direct Object Reference) Protection' do
    let!(:other_post) { create(:post, user: other_user, content: 'Private user content') }

    it 'prevents updating another user post' do
      patch post_path(other_post), params: { post: { content: 'Hacked!' } }
      expect(other_post.reload.content).not_to eq('Hacked!')
    end

    it 'prevents deleting another user post' do
      expect {
        delete post_path(other_post)
      }.not_to change(Post, :count)
    end
  end

  describe 'Mass Assignment Protection' do
    it 'prevents regular user from escalating role via params' do
      patch user_registration_path, params: { user: { super_admin: true } }
      expect(user.reload.super_admin?).to be false
    end
  end
end
