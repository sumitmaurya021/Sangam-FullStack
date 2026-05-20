require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when user is not logged in" do
      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end
      
      it "displays landing page" do
        get root_path
        expect(response.body).to include('Sangam')
        expect(response.body).to include('Connect with friends')
      end
      
      it "has sign in button" do
        get root_path
        expect(response.body).to include('Sign In')
      end
      
      it "has sign up button" do
        get root_path
        expect(response.body).to include('Sign Up')
      end
      
      it "has gradient background" do
        get root_path
        expect(response.body).to include('linear-gradient')
      end
    end
    
    context "when user is logged in" do
      let(:user) { create(:user) }
      
      before { sign_in user }
      
      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end
      
      it "displays dashboard" do
        get root_path
        expect(response.body).to include('dashboard-header')
      end
      
      it "includes CSS stylesheet link" do
        get root_path
        expect(response.body).to include('home/dashboard')
      end
      
      it "displays welcome message" do
        get root_path
        expect(response.body).to include('Welcome')
      end
      
      it "displays user email" do
        get root_path
        expect(response.body).to include(user.email)
      end
      
      it "has header navigation" do
        get root_path
        expect(response.body).to include('header-container')
        expect(response.body).to include('header-left')
        expect(response.body).to include('header-right')
      end
      
      it "has search input" do
        get root_path
        expect(response.body).to include('search-input')
        expect(response.body).to include('Search Sangam')
      end
      
      it "has profile dropdown" do
        get root_path
        expect(response.body).to include('profile-dropdown')
        expect(response.body).to include('profile-button')
        expect(response.body).to include('dropdown-menu')
      end
      
      it "has logout button in dropdown" do
        get root_path
        expect(response.body).to include('Log Out')
      end
      
      it "has sidebar navigation" do
        get root_path
        expect(response.body).to include('dashboard-sidebar')
        expect(response.body).to include('sidebar-menu')
      end
      
      it "has welcome card" do
        get root_path
        expect(response.body).to include('welcome-card')
      end
      
      it "has widgets section" do
        get root_path
        expect(response.body).to include('dashboard-widgets')
      end
      
      it "has notification icon" do
        get root_path
        expect(response.body).to include('Notifications')
      end
      
      it "displays user initial in profile button" do
        get root_path
        expect(response.body).to include(user.email[0].upcase)
      end
    end
  end
end
