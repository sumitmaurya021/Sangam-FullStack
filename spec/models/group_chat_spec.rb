require 'rails_helper'

RSpec.describe GroupChat, type: :model do
  let(:owner)  { create(:user) }
  let(:alice)  { create(:user) }
  let(:bob)    { create(:user) }

  subject(:gc) { GroupChat.create!(name: 'Test Group', owner: owner) }

  # ── Associations ───────────────────────────────────────────────
  it { is_expected.to belong_to(:owner).class_name('User') }
  it { is_expected.to have_many(:group_chat_members).dependent(:destroy) }
  it { is_expected.to have_many(:members).through(:group_chat_members) }
  it { is_expected.to have_many(:group_chat_messages).dependent(:destroy) }

  # ── Validations ────────────────────────────────────────────────
  it { is_expected.to validate_presence_of(:name) }

  it 'is invalid without a name' do
    gc_no_name = GroupChat.new(owner: owner)
    expect(gc_no_name).not_to be_valid
  end

  # ── after_create: owner auto-added as admin ─────────────────────
  describe 'after_create' do
    it 'adds the owner as an admin member' do
      expect(gc.member?(owner)).to be true
      expect(gc.admin?(owner)).to  be true
    end

    it 'sets members_count to 1' do
      expect(gc.members_count).to eq 1
    end
  end

  # ── member? / admin? ───────────────────────────────────────────
  describe '#member?' do
    it 'returns true for members' do
      gc.add_member!(alice)
      expect(gc.member?(alice)).to be true
    end

    it 'returns false for non-members' do
      expect(gc.member?(bob)).to be false
    end
  end

  describe '#admin?' do
    it 'returns true only for admin role' do
      gc.add_member!(alice)
      expect(gc.admin?(alice)).to be false
      gc.group_chat_members.find_by(user: alice).update!(role: 'admin')
      expect(gc.admin?(alice)).to be true
    end
  end

  # ── add_member! / remove_member! ──────────────────────────────
  describe '#add_member!' do
    it 'increments members_count' do
      expect { gc.add_member!(alice) }.to change { gc.reload.members_count }.by(1)
    end

    it 'is idempotent (no duplicate)' do
      gc.add_member!(alice)
      expect { gc.add_member!(alice) }.not_to change { gc.reload.members_count }
    end
  end

  describe '#remove_member!' do
    before { gc.add_member!(alice) }

    it 'decrements members_count' do
      expect { gc.remove_member!(alice) }.to change { gc.reload.members_count }.by(-1)
    end

    it 'removes the membership record' do
      gc.remove_member!(alice)
      expect(gc.member?(alice)).to be false
    end
  end

  # ── Scopes ─────────────────────────────────────────────────────
  describe '.for_user' do
    it 'returns only groups the user is a member of' do
      gc  # creates group with owner
      gc2 = GroupChat.create!(name: 'Other Group', owner: alice)
      expect(GroupChat.for_user(owner)).to include(gc)
      expect(GroupChat.for_user(owner)).not_to include(gc2)
    end
  end
end

RSpec.describe GroupChatMember, type: :model do
  it { is_expected.to belong_to(:group_chat) }
  it { is_expected.to belong_to(:user) }

  it 'prevents duplicate memberships' do
    owner = create(:user)
    gc    = GroupChat.create!(name: 'G', owner: owner)
    expect { gc.group_chat_members.create!(user: owner, role: 'member') }
      .to raise_error(ActiveRecord::RecordInvalid)
  end
end

RSpec.describe GroupChatMessage, type: :model do
  let(:owner)   { create(:user) }
  let(:gc)      { GroupChat.create!(name: 'G', owner: owner) }

  it { is_expected.to belong_to(:group_chat) }
  it { is_expected.to belong_to(:user) }

  describe 'validations' do
    it 'requires body for text messages' do
      msg = GroupChatMessage.new(group_chat: gc, user: owner, message_type: 'text')
      expect(msg).not_to be_valid
      expect(msg.errors[:body]).to be_present
    end

    it 'is valid with body for text messages' do
      msg = GroupChatMessage.new(group_chat: gc, user: owner, message_type: 'text', body: 'Hello')
      expect(msg).to be_valid
    end
  end

  describe '#soft_delete!' do
    it 'marks message as deleted' do
      msg = GroupChatMessage.create!(group_chat: gc, user: owner, message_type: 'text', body: 'Hi')
      msg.soft_delete!
      expect(msg.reload.deleted).to be true
    end
  end
end
