require 'rails_helper'

RSpec.describe AiModerationService do
  describe '#analyze' do
    context 'with safe text' do
      it 'returns approved action' do
        service = AiModerationService.new('Hello everyone, hope you have a great day!')
        result = service.analyze

        expect(result[:flagged]).to be false
        expect(result[:action_taken]).to eq('approved')
      end
    end

    context 'with severe toxicity' do
      it 'blocks severe abusive language' do
        service = AiModerationService.new('I will fuck and kill yourself asshole')
        result = service.analyze

        expect(result[:flagged]).to be true
        expect(result[:action_taken]).to eq('blocked')
      end
    end

    context 'with mild profanity or spam' do
      it 'flags content for review' do
        allow(ENV).to receive(:[]).with('GROQ_API_KEY').and_return(nil)
        service = AiModerationService.new('This is stupid idiot crap')
        result = service.analyze

        expect(result[:flagged]).to be true
        expect(result[:action_taken]).to eq('flagged_for_review')
      end
    end
  end
end
