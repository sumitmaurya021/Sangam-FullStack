require 'rails_helper'

RSpec.describe AiTranslationService do
  describe '#translate' do
    context 'with text and target language' do
      it 'translates text into target language' do
        service = AiTranslationService.new('Hello friend', 'Hindi')
        result = service.translate

        expect(result[:success]).to be true
        expect(result[:translated_text]).to be_present
      end
    end

    context 'with missing text' do
      it 'returns error' do
        service = AiTranslationService.new('', 'Hindi')
        result = service.translate

        expect(result[:success]).to be false
        expect(result[:error]).to include('Text or target language is missing')
      end
    end
  end
end
