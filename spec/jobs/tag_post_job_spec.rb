require 'rails_helper'

RSpec.describe TagPostJob, type: :job do
  include ActiveJob::TestHelper

  let(:post_record) { create(:post, content: 'Learning Rails 8 and AI Development') }

  it 'gracefully returns if post is missing or GROQ_API_KEY is not set' do
    expect {
      TagPostJob.perform_now(-1)
    }.not_to raise_error
  end

  it 'executes perform_now without crashing' do
    allow(ENV).to receive(:[]).with('GROQ_API_KEY').and_return('mock_key')
    category = CategoryTag.create!(name: 'Technology')

    stub_request(:post, 'https://api.groq.com/openai/v1/chat/completions')
      .to_return(
        status: 200,
        body: {
          choices: [
            {
              message: {
                content: { tags: [{ name: 'Technology', confidence: 0.95 }] }.to_json
              }
            }
          ]
        }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    expect {
      TagPostJob.perform_now(post_record.id)
    }.to change(PostCategoryTag, :count).by(1)
  end
end
