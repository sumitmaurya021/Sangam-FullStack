require 'rails_helper'

RSpec.describe "Conversations", type: :request do
  let(:user)      { create(:user) }
  let(:other_user) { create(:user) }

  before do
    allow(User).to receive(:ai_bot).and_return(create(:user, email: 'ai@bot.com', name: 'AI Bot'))
    sign_in user
  end

  describe "GET /conversations" do
    it "returns http success" do
      get conversations_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /conversations" do
    it "creates or finds a conversation" do
      post conversations_path, params: { recipient_id: other_user.id }, as: :json
      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to have_key('conversation_id')
    end

    it "returns error when trying to converse with yourself" do
      post conversations_path, params: { recipient_id: user.id }, as: :json
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /conversations/:id" do
    let!(:conversation) { Conversation.find_or_create_between(user, other_user) }

    it "returns http success" do
      get conversation_path(conversation)
      expect(response).to have_http_status(:success)
    end
  end

  describe "DELETE /conversations/:id" do
    let!(:conversation) { Conversation.find_or_create_between(user, other_user) }

    it "deletes the conversation" do
      expect {
        delete conversation_path(conversation)
      }.to change(Conversation, :count).by(-1)
      expect(response).to redirect_to(conversations_path)
    end
  end
end
