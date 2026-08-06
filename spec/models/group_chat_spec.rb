require 'rails_helper'

RSpec.describe GroupChat, type: :model do
  let(:owner) { create(:user) }
  let(:member) { create(:user) }
  let(:group_chat) { create(:group_chat, owner: owner) }

  describe 'associations' do
    it { should belong_to(:owner).class_name('User') }
    it { should have_many(:group_chat_members).dependent(:destroy) }
    it { should have_many(:members).through(:group_chat_members).source(:user) }
    it { should have_many(:group_chat_messages).dependent(:destroy) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'membership methods' do
    before do
      group_chat.add_member!(member)
    end

    it 'adds member and verifies membership' do
      expect(group_chat.member?(member)).to be true
      expect(group_chat.members).to include(member)
    end

    it 'removes member' do
      group_chat.remove_member!(member)
      expect(group_chat.member?(member)).to be false
    end
  end
end
