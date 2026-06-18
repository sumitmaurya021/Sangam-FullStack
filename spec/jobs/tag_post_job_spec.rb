require 'rails_helper'

RSpec.describe TagPostJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:post) { create(:post, user: user, content: 'Learning about machine learning and artificial intelligence.') }
    let!(:tech_tag) { create(:category_tag, name: 'Technology', slug: 'technology') }
    let!(:edu_tag) { create(:category_tag, name: 'Education', slug: 'education') }

    it 'calls the Groq API and creates PostCategoryTag records' do
      mock_response = Net::HTTPSuccess.new(1.0, '200', 'OK')
      allow(mock_response).to receive(:body).and_return({
        choices: [
          {
            message: {
              content: "{\"tags\": [{\"name\": \"Technology\", \"confidence\": 0.95}, {\"name\": \"Education\", \"confidence\": 0.8}]}"
            }
          }
        ]
      }.to_json)

      expect(Net::HTTP).to receive(:start).and_return(mock_response)

      TagPostJob.new.perform(post.id)

      expect(post.post_category_tags.count).to eq(2)
      
      tech_pct = post.post_category_tags.find_by(category_tag: tech_tag)
      expect(tech_pct).to be_present
      expect(tech_pct.confidence_score).to eq(0.95)

      edu_pct = post.post_category_tags.find_by(category_tag: edu_tag)
      expect(edu_pct).to be_present
      expect(edu_pct.confidence_score).to eq(0.8)
    end

    it 'handles API failures gracefully' do
      mock_response = double("response", code: "500", body: "Server Error")
      allow(Net::HTTP).to receive(:start).and_return(mock_response)

      expect {
        TagPostJob.new.perform(post.id)
      }.not_to raise_error

      expect(post.post_category_tags.count).to eq(0)
    end
  end
end
