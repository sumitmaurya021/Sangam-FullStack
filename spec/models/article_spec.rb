require 'rails_helper'

RSpec.describe Article, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(5).is_at_most(200) }
    it { should validate_presence_of(:content) }
  end

  describe 'scopes' do
    let!(:published_article) { create(:article, user: user, content: 'Sample content for article', published: true) }
    let!(:draft_article) { create(:article, user: user, content: 'Sample content for draft article', published: false) }

    it 'returns published articles' do
      expect(Article.published).to include(published_article)
      expect(Article.published).not_to include(draft_article)
    end
  end
end
