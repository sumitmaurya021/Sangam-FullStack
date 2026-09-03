require 'rails_helper'

RSpec.describe "GroupChats", type: :request do
  let(:user)  { create(:user) }
  let(:other) { create(:user) }
  let!(:group_chat) { create(:group_chat, owner: user) }

  before do
    group_chat.add_member!(user)
    sign_in user
  end

  describe "GET /group_chats" do
    it "returns http success" do
      get group_chats_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /group_chats/:id" do
    it "returns http success for member" do
      get group_chat_path(group_chat)
      expect(response).to have_http_status(:success)
    end

    it "redirects non-member" do
      other_chat = create(:group_chat, owner: create(:user))
      get group_chat_path(other_chat)
      expect(response).to redirect_to(group_chats_path)
    end
  end

  describe "POST /group_chats" do
    it "creates a group chat" do
      expect {
        post group_chats_path,
          params: { group_chat: { name: 'Weekend Crew', description: 'Fun group' } }
      }.to change(GroupChat, :count).by(1)
      expect(response).to redirect_to(group_chat_path(GroupChat.last))
    end
  end

  describe "DELETE /group_chats/:id" do
    it "deletes the group chat as owner" do
      expect {
        delete group_chat_path(group_chat)
      }.to change(GroupChat, :count).by(-1)
      expect(response).to redirect_to(group_chats_path)
    end

    it "prevents non-owner from deleting" do
      group_chat.add_member!(other)
      sign_in other
      expect {
        delete group_chat_path(group_chat), as: :json
      }.not_to change(GroupChat, :count)
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /group_chats/:id/add_member" do
    it "adds a member as admin" do
      post add_member_group_chat_path(group_chat), params: { user_id: other.id }, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe "DELETE /group_chats/:id/leave" do
    it "allows member to leave" do
      group_chat.add_member!(other)
      sign_in other
      delete leave_group_chat_path(group_chat)
      expect(response).to redirect_to(group_chats_path)
    end

    it "prevents owner from leaving" do
      delete leave_group_chat_path(group_chat)
      expect(response).to redirect_to(group_chats_path)
    end
  end
end
