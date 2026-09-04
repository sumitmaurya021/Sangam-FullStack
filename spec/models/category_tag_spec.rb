require 'rails_helper'

RSpec.describe CategoryTag, type: :model do
  it 'is valid with valid attributes' do
    tag = CategoryTag.new(name: 'Technology')
    expect(tag).to be_valid
  end
end
