require 'rails_helper'

RSpec.describe Conversation, type: :model do
  let(:sender) { create(:user) }
  let(:recipient) { create(:user) }

  describe 'associations' do
    it { should belong_to(:sender).class_name('User') }
    it { should belong_to(:recipient).class_name('User') }
    it { should have_many(:messages).dependent(:destroy) }
  end

  describe 'validations' do
    it 'validates sender and recipient presence' do
      expect(build(:conversation, sender: nil)).not_to be_valid
      expect(build(:conversation, recipient: nil)).not_to be_valid
    end

    it 'prevents self conversation' do
      conv = build(:conversation, sender: sender, recipient: sender)
      expect(conv).not_to be_valid
      expect(conv.errors[:base]).to include("Cannot have a conversation with yourself")
    end
  end

  describe 'scopes and helper methods' do
    let!(:conv) { Conversation.find_or_create_between(sender, recipient) }

    it '.between returns conversation regardless of sender/recipient order' do
      expect(Conversation.between(sender, recipient)).to eq(conv)
      expect(Conversation.between(recipient, sender)).to eq(conv)
    end

    it '#other_participant returns the opposing user' do
      expect(conv.other_participant(sender)).to eq(recipient)
      expect(conv.other_participant(recipient)).to eq(sender)
    end

    it 'marks messages as read' do
      msg = create(:message, conversation: conv, user: recipient, read_at: nil)
      expect(conv.unread_count_for(sender)).to eq(1)

      conv.mark_as_read_for!(sender)
      expect(conv.unread_count_for(sender)).to eq(0)
    end
  end
end
