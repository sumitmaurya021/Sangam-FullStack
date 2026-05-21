require 'rails_helper'

RSpec.describe "Friendships", type: :request do
  let(:user) { create(:user) }
  let(:friend) { create(:user) }
  
  before { sign_in user }

  describe "POST /friendships" do
    it "creates a friend request" do
      expect {
        post friendships_path, params: { friend_id: friend.id }
      }.to change(Friendship, :count).by(1)
    end
    
    it "sets status to pending" do
      post friendships_path, params: { friend_id: friend.id }
      friendship = Friendship.last
      expect(friendship.status).to eq('pending')
    end
    
    it "redirects back" do
      post friendships_path, params: { friend_id: friend.id }
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /friendships/:id/accept" do
    let(:friendship) { Friendship.create!(user: friend, friend: user, status: 'pending') }
    
    it "accepts the friend request" do
      patch accept_friendship_path(friendship)
      friendship.reload
      expect(friendship.status).to eq('accepted')
    end
    
    it "redirects back" do
      patch accept_friendship_path(friendship)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "PATCH /friendships/:id/reject" do
    let(:friendship) { Friendship.create!(user: friend, friend: user, status: 'pending') }
    
    it "rejects the friend request" do
      patch reject_friendship_path(friendship)
      friendship.reload
      expect(friendship.status).to eq('rejected')
    end
    
    it "redirects back" do
      patch reject_friendship_path(friendship)
      expect(response).to have_http_status(:redirect)
    end
  end

  describe "DELETE /friendships/:id" do
    let!(:friendship) { Friendship.create!(user: user, friend: friend, status: 'accepted') }
    
    it "deletes the friendship" do
      expect {
        delete friendship_path(friendship)
      }.to change(Friendship, :count).by(-1)
    end
    
    it "redirects back" do
      delete friendship_path(friendship)
      expect(response).to have_http_status(:redirect)
    end
  end
end
