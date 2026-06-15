require 'rails_helper'

RSpec.describe Bookmark, type: :model do
  let(:user)  { create(:user) }
  let(:post)  { Post.create!(user: user, content: 'Hello', visibility: 'public') }
  let(:reel)  { Reel.create!(user: user) }

  # ── Associations ───────────────────────────────────────
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:bookmarkable) }

  # ── Post bookmark ───────────────────────────────────────
  describe 'bookmarking a Post' do
    subject(:bm) do
      Bookmark.new(user: user, bookmarkable: post, post_id: post.id)
    end

    it 'is valid' do
      expect(bm).to be_valid
    end

    it 'persists with correct polymorphic type' do
      bm.save!
      expect(bm.reload.bookmarkable_type).to eq 'Post'
      expect(bm.reload.bookmarkable_id).to   eq post.id
    end

    it 'prevents duplicate post bookmarks' do
      bm.save!
      dup = Bookmark.new(user: user, bookmarkable: post, post_id: post.id)
      expect(dup).not_to be_valid
    end
  end

  # ── Reel bookmark ───────────────────────────────────────
  describe 'bookmarking a Reel' do
    subject(:bm) { Bookmark.new(user: user, bookmarkable: reel) }

    it 'is valid without post_id' do
      expect(bm).to be_valid
    end

    it 'persists with correct polymorphic type' do
      bm.save!
      expect(bm.reload.bookmarkable_type).to eq 'Reel'
      expect(bm.reload.bookmarkable_id).to   eq reel.id
    end

    it 'prevents duplicate reel bookmarks' do
      bm.save!
      dup = Bookmark.new(user: user, bookmarkable: reel)
      expect(dup).not_to be_valid
    end
  end

  # ── Scopes ─────────────────────────────────────────────
  describe 'scopes' do
    before do
      Bookmark.create!(user: user, bookmarkable: post, post_id: post.id)
      Bookmark.create!(user: user, bookmarkable: reel)
    end

    it '.for_posts returns only Post bookmarks' do
      expect(Bookmark.for_posts.map(&:bookmarkable_type).uniq).to eq ['Post']
    end

    it '.for_reels returns only Reel bookmarks' do
      expect(Bookmark.for_reels.map(&:bookmarkable_type).uniq).to eq ['Reel']
    end
  end

  # ── Model helpers ───────────────────────────────────────
  describe 'Reel#bookmarked_by?' do
    it 'returns true after bookmarking' do
      Bookmark.create!(user: user, bookmarkable: reel)
      expect(reel.bookmarked_by?(user)).to be true
    end

    it 'returns false when not bookmarked' do
      expect(reel.bookmarked_by?(user)).to be false
    end
  end

  describe '.for class method' do
    it 'finds an existing bookmark' do
      bm = Bookmark.create!(user: user, bookmarkable: reel)
      expect(Bookmark.for(user: user, bookmarkable: reel)).to eq bm
    end

    it 'returns nil when not found' do
      expect(Bookmark.for(user: user, bookmarkable: reel)).to be_nil
    end
  end
end
