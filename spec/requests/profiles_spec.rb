require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  
  before { sign_in user }

  describe "GET /profile/:id" do
    it "returns http success for own profile" do
      get profile_path(user)
      expect(response).to have_http_status(:success)
    end
    
    it "returns http success for other user's profile" do
      get profile_path(other_user)
      expect(response).to have_http_status(:success)
    end
    
    it "displays user information" do
      get profile_path(user)
      expect(response.body).to include(user.name)
    end
  end

  describe "GET /profile/:id/friends" do
    it "returns http success" do
      get profile_friends_path(user)
      expect(response).to have_http_status(:success)
    end
    
    it "displays friends list" do
      friend = create(:user)
      Friendship.create!(user: user, friend: friend, status: 'accepted')
      
      get profile_friends_path(user)
      expect(response.body).to include('Friends')
    end
  end
end
