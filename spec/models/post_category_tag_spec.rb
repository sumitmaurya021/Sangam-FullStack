require 'rails_helper'

RSpec.describe PostCategoryTag, type: :model do
  describe 'associations' do
    it { should belong_to(:post) }
    it { should belong_to(:category_tag) }
  end
end
