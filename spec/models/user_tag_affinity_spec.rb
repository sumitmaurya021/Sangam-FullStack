require 'rails_helper'

RSpec.describe UserTagAffinity, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:category_tag) }
  end
end
