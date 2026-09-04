require 'rails_helper'

RSpec.describe "Messages", type: :request do
  let(:user)        { create(:user) }
  let(:other_user)  { create(:user) }
  let!(:conversation) { Conversation.find_or_create_between(user, other_user) }

  before { sign_in user }

  describe "POST /conversations/:conversation_id/messages" do
    it "creates a message" do
      expect {
        post conversation_messages_path(conversation),
          params: { message: { body: 'Hello there!', message_type: 'text' } },
          as: :json
      }.to change(Message, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "rejects empty message body" do
      expect {
        post conversation_messages_path(conversation),
          params: { message: { body: '', message_type: 'text' } },
          as: :json
      }.not_to change(Message, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /conversations/:conversation_id/messages/:id" do
    let!(:message) { create(:message, conversation: conversation, user: user, body: 'Hi!') }

    it "soft deletes the message when owner" do
      delete conversation_message_path(conversation, message), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "prevents non-owner from deleting" do
      sign_in other_user
      other_msg = create(:message, conversation: conversation, user: user)
      delete conversation_message_path(conversation, other_msg), as: :json
      expect(response).to have_http_status(:forbidden)
    end
  end
end
