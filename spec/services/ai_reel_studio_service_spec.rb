require 'rails_helper'

RSpec.describe AiReelStudioService do
  describe '#generate' do
    it 'converts article text into 3 vertical reel story slides' do
      article_text = "Ruby on Rails 8 brings incredible new fullstack features. Solid Queue and Solid Cache now power ActiveJob and Cache without Redis. AI capabilities make application development super productive."
      service = AiReelStudioService.new(article_text, 'Rails 8 Innovations')
      result = service.generate

      expect(result[:success]).to be true
      expect(result[:reel_title]).to be_present
      expect(result[:slides]).to be_an(Array)
      expect(result[:slides].length).to eq(3)
      expect(result[:slides].first).to have_key('headline')
      expect(result[:slides].first).to have_key('bg_gradient')
    end
  end
end
