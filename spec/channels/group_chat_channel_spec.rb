require 'rails_helper'

RSpec.describe GroupChatChannel, type: :channel do
  let(:user) { create(:user) }
  let(:group_chat) { create(:group_chat, owner: user) }

  before do
    stub_connection current_user: user
    group_chat.add_member!(user)
  end

  describe '#subscribed' do
    it 'subscribes to the group chat stream when user is a member' do
      subscribe(group_chat_id: group_chat.id)
      expect(subscription).to be_confirmed
      expect(subscription.streams).to include("group_chat_#{group_chat.id}")
    end

    it 'rejects subscription when user is not a member' do
      other_chat = create(:group_chat, owner: create(:user))
      subscribe(group_chat_id: other_chat.id)
      expect(subscription).to be_rejected
    end

    it 'rejects subscription when group chat not found' do
      subscribe(group_chat_id: 9_999_999)
      expect(subscription).to be_rejected
    end
  end

  describe '#unsubscribed' do
    it 'stops all streams on unsubscribe' do
      subscribe(group_chat_id: group_chat.id)
      expect { unsubscribe }.not_to raise_error
    end
  end

  describe '#typing' do
    it 'broadcasts typing indicator to group chat stream' do
      subscribe(group_chat_id: group_chat.id)
      expect {
        perform :typing, group_chat_id: group_chat.id, is_typing: true
      }.to have_broadcasted_to("group_chat_#{group_chat.id}").with(
        hash_including(type: 'group_typing', user_id: user.id, is_typing: true)
      )
    end
  end
end
