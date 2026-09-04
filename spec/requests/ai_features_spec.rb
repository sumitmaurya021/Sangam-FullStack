require 'rails_helper'

RSpec.describe 'AI Features API', type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  describe 'POST /api/ai/generate_caption' do
    it 'returns generated caption when successful' do
      service_double = instance_double(AiCaptionGeneratorService, generate: { success: true, caption: 'A stunning sunset!' })
      allow(AiCaptionGeneratorService).to receive(:new).and_return(service_double)

      post '/api/ai/generate_caption', params: { image: 'fake_image' }
      expect(response).to have_http_status(:ok)
      expect(json_response['caption']).to eq('A stunning sunset!')
    end

    it 'returns unprocessable_entity when service fails' do
      service_double = instance_double(AiCaptionGeneratorService, generate: { success: false })
      allow(AiCaptionGeneratorService).to receive(:new).and_return(service_double)

      post '/api/ai/generate_caption'
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'POST /api/ai/generate_smart_replies' do
    let(:other_user) { create(:user) }
    let(:conversation) { create(:conversation, sender: user, recipient: other_user) }

    it 'returns fallback replies when conversation has no text messages' do
      post '/api/ai/generate_smart_replies', params: { conversation_id: conversation.id }
      expect(response).to have_http_status(:ok)
      expect(json_response['replies']).to include('Hi!')
    end

    it 'returns AI smart replies when last message exists' do
      create(:message, conversation: conversation, user: other_user, body: 'Hey how are you?')

      service_double = instance_double(AiSmartReplyService, generate: { success: true, replies: ['Good thanks!', 'Not bad!'] })
      allow(AiSmartReplyService).to receive(:new).and_return(service_double)

      post '/api/ai/generate_smart_replies', params: { conversation_id: conversation.id }
      expect(response).to have_http_status(:ok)
      expect(json_response['replies']).to eq(['Good thanks!', 'Not bad!'])
    end
  end

  describe 'POST /api/ai/generate_article_content' do
    it 'returns 422 if prompt is missing' do
      post '/api/ai/generate_article_content', params: { prompt: '' }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'generates article HTML content' do
      service_double = instance_double(AiArticleAssistantService, generate: { success: true, html: '<p>Article content</p>' })
      allow(AiArticleAssistantService).to receive(:new).and_return(service_double)

      post '/api/ai/generate_article_content', params: { prompt: 'Write about AI' }
      expect(response).to have_http_status(:ok)
      expect(json_response['html']).to eq('<p>Article content</p>')
    end
  end

  describe 'POST /api/ai/rewrite_message' do
    it 'rewrites message text with requested tone' do
      service_double = instance_double(AiMultimodalChatService, rewrite_message: { success: true, rewritten_text: 'Dear Sir, I am writing...' })
      allow(AiMultimodalChatService).to receive(:new).and_return(service_double)

      post '/api/ai/rewrite_message', params: { text: 'hey whats up', tone: 'formal' }
      expect(response).to have_http_status(:ok)
      expect(json_response['text']).to eq('Dear Sir, I am writing...')
    end
  end

  describe 'POST /api/ai/translate_text' do
    it 'translates text into target language' do
      service_double = instance_double(AiTranslationService, translate: { success: true, translated_text: 'Hola amigo' })
      allow(AiTranslationService).to receive(:new).and_return(service_double)

      post '/api/ai/translate_text', params: { text: 'Hello friend', target_language: 'Spanish' }
      expect(response).to have_http_status(:ok)
      expect(json_response['translated_text']).to eq('Hola amigo')
    end
  end

  describe 'POST /api/ai/search' do
    it 'returns search answer and matching results' do
      service_double = instance_double(AiSearchService, generate: { success: true, answer: 'Found 2 posts', results: [] })
      allow(AiSearchService).to receive(:new).and_return(service_double)

      post '/api/ai/search', params: { query: 'rails 8 features' }
      expect(response).to have_http_status(:ok)
      expect(json_response['answer']).to eq('Found 2 posts')
    end
  end

  private

  def json_response
    JSON.parse(response.body)
  end
end
