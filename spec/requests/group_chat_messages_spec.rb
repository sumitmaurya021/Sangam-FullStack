require 'rails_helper'

RSpec.describe "GroupChatMessages", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let!(:group_chat) { create(:group_chat, owner: user) }

  before do
    group_chat.add_member!(user)
    group_chat.add_member!(other_user)
    sign_in user
  end

  describe "GET /group_chats/:group_chat_id/messages" do
    it "returns JSON messages for a member" do
      create(:group_chat_message, group_chat: group_chat, user: user)
      get group_chat_group_chat_messages_path(group_chat), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('messages')
    end

    it "returns 403 for non-members" do
      non_member = create(:user)
      sign_in non_member
      get group_chat_group_chat_messages_path(group_chat), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "POST /group_chats/:group_chat_id/messages" do
    it "creates a message for a member" do
      expect {
        post group_chat_group_chat_messages_path(group_chat),
          params: { group_chat_message: { body: 'Hello group!', message_type: 'text' } },
          as: :json
      }.to change(GroupChatMessage, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "rejects empty message body" do
      expect {
        post group_chat_group_chat_messages_path(group_chat),
          params: { group_chat_message: { body: '', message_type: 'text' } },
          as: :json
      }.not_to change(GroupChatMessage, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "rejects non-member from sending" do
      non_member = create(:user)
      sign_in non_member
      post group_chat_group_chat_messages_path(group_chat),
        params: { group_chat_message: { body: 'Hack!', message_type: 'text' } },
        as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /group_chats/:group_chat_id/messages/:id" do
    let!(:message) { create(:group_chat_message, group_chat: group_chat, user: user) }

    it "soft deletes own message" do
      delete group_chat_group_chat_message_path(group_chat, message), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "prevents non-owner non-admin from deleting" do
      sign_in other_user
      other_message = create(:group_chat_message, group_chat: group_chat, user: user)
      delete group_chat_group_chat_message_path(group_chat, other_message), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
