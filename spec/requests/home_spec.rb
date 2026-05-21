require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when user is not logged in" do
      it "redirects to sign in" do
        get root_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    
    context "when user is logged in" do
      let(:user) { create(:user) }
      
      before { sign_in user }
      
      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end
      
      it "displays posts feed" do
        get root_path
        expect(response.body).to include('feed-container')
      end
      
      it "includes CSS stylesheet link" do
        get root_path
        expect(response.body).to include('posts/feed')
      end
      
      it "has header navigation" do
        get root_path
        expect(response.body).to include('fb-header')
      end
      
      it "has create post section" do
        get root_path
        expect(response.body).to include('create-post-card')
      end
      
      it "has search input in header" do
        get root_path
        expect(response.body).to include('Search Sangam')
      end
      
      it "has profile dropdown" do
        get root_path
        expect(response.body).to include('fb-profile-btn')
      end
    end
  end
end
