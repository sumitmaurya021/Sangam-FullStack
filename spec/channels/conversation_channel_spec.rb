require 'rails_helper'

RSpec.describe ConversationChannel, type: :channel do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }
  let(:conversation) { create(:conversation, sender: sender, recipient: recipient) }

  before do
    stub_connection current_user: sender
  end

  it 'subscribes to conversation stream when authorized' do
    subscribe(conversation_id: conversation.id)
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("conversation_#{conversation.id}")
  end

  it 'rejects subscription when unauthorized user attempts to join' do
    unauthorized_user = create(:user)
    stub_connection current_user: unauthorized_user

    subscribe(conversation_id: conversation.id)
    expect(subscription).to be_rejected
  end
end
