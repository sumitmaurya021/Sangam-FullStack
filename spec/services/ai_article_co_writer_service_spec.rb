require 'rails_helper'

RSpec.describe AiArticleCoWriterService do
  describe '#execute' do
    context 'with continue mode' do
      it 'generates next paragraphs for article' do
        service = AiArticleCoWriterService.new('Building Modern Web Apps with Ruby on Rails 8', 'Rails 8 introduces Solid Cache and Solid Queue.', 'continue')
        result = service.execute

        expect(result[:success]).to be true
        expect(result[:generated_content]).to be_present
      end
    end

    context 'with outline mode' do
      it 'generates article outline' do
        service = AiArticleCoWriterService.new('Artificial Intelligence in Social Platforms', '', 'outline')
        result = service.execute

        expect(result[:success]).to be true
        expect(result[:generated_content]).to include('###')
      end
    end
  end
end
