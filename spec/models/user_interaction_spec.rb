require 'rails_helper'

RSpec.describe UserInteraction, type: :model do
  let(:user) { create(:user) }
  let(:stranger) { create(:user) }
  let(:post) { create(:post, user: stranger) }
  let(:category_tech) { create(:category_tag, name: 'Technology', slug: 'tech') }
  let!(:post_tag) { create(:post_category_tag, post: post, category_tag: category_tech, confidence_score: 0.8) }

  describe 'callbacks' do
    describe 'after_create :bump_affinities' do
      it 'creates a new affinity if it does not exist' do
        expect {
          create(:user_interaction, user: user, post: post, interaction_type: 'like')
        }.to change(UserTagAffinity, :count).by(1)

        affinity = UserTagAffinity.find_by(user: user, category_tag: category_tech)
        # weight for 'like' is 3. 3 * 0.8 = 2.4
        expect(affinity.score).to be_within(0.01).of(2.4)
      end

      it 'updates an existing affinity score' do
        existing_affinity = create(:user_tag_affinity, user: user, category_tag: category_tech, score: 10.0)

        create(:user_interaction, user: user, post: post, interaction_type: 'comment')
        
        # weight for 'comment' is 5. 5 * 0.8 = 4.0. Total = 14.0
        expect(existing_affinity.reload.score).to be_within(0.01).of(14.0)
      end

      it 'decreases score for negative interactions like hide' do
        existing_affinity = create(:user_tag_affinity, user: user, category_tag: category_tech, score: 10.0)

        create(:user_interaction, user: user, post: post, interaction_type: 'hide')
        
        # weight for 'hide' is -8. -8 * 0.8 = -6.4. Total = 3.6
        expect(existing_affinity.reload.score).to be_within(0.01).of(3.6)
      end
    end
  end
end
