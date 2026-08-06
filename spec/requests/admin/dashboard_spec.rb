require 'rails_helper'

RSpec.describe 'Admin Dashboard', type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }

  context 'when signed in as regular user' do
    before { sign_in regular_user }

    it 'redirects away with access denied alert' do
      get admin_dashboard_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('Access denied')
    end
  end

  context 'when signed in as super admin' do
    before { sign_in super_admin }

    it 'renders admin dashboard index successfully' do
      get admin_dashboard_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders admin users list page' do
      get admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders admin posts list page' do
      get admin_posts_path
      expect(response).to have_http_status(:ok)
    end

    it 'renders moderation panel' do
      get admin_moderation_path
      expect(response).to have_http_status(:ok)
    end
  end
end
