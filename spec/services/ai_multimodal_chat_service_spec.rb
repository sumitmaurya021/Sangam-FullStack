require 'rails_helper'

RSpec.describe AiMultimodalChatService do
  describe '#summarize_conversation' do
    it 'summarizes array of message strings into bullet points' do
      messages = [
        "Hey! Are we still meeting for the project discussion today?",
        "Yes, 4 PM at the library works for me.",
        "Great! I will bring the slide deck."
      ]

      service = AiMultimodalChatService.new(messages: messages)
      result = service.summarize_conversation

      expect(result[:success]).to be true
      expect(result[:summary]).to be_present
      expect(result[:summary]).to include('•')
    end
  end

  describe '#rewrite_message' do
    it 'rewrites text into specified tone' do
      service = AiMultimodalChatService.new(text: 'greetings i will come late', tone: 'formal')
      result = service.rewrite_message

      expect(result[:success]).to be true
      expect(result[:rewritten_text]).to be_present
    end
  end
end
