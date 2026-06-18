require 'rails_helper'

RSpec.describe DecayUserAffinitiesJob, type: :job do
  describe '#perform' do
    it 'multiplies all user tag affinities by the decay factor (0.95)' do
      user = create(:user)
      tag1 = create(:category_tag, name: 'Tech', slug: 'tech')
      tag2 = create(:category_tag, name: 'Sports', slug: 'sports')
      
      affinity1 = create(:user_tag_affinity, user: user, category_tag: tag1, score: 100.0)
      affinity2 = create(:user_tag_affinity, user: user, category_tag: tag2, score: 50.0)

      DecayUserAffinitiesJob.new.perform

      expect(affinity1.reload.score).to be_within(0.01).of(95.0)
      expect(affinity2.reload.score).to be_within(0.01).of(47.5)
    end
  end
end
