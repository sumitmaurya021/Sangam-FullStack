require 'rails_helper'

RSpec.describe AiAudioTranscriptionService do
  describe '#transcribe' do
    context 'without attachment' do
      it 'returns error' do
        service = AiAudioTranscriptionService.new(nil)
        result = service.transcribe

        expect(result[:success]).to be false
        expect(result[:error]).to include('No audio attachment')
      end
    end

    context 'with attached audio file' do
      let(:user1) { User.create!(name: 'Audio Tester 1', email: "audio1_#{SecureRandom.hex(4)}@test.com", password: 'password123') }
      let(:user2) { User.create!(name: 'Audio Tester 2', email: "audio2_#{SecureRandom.hex(4)}@test.com", password: 'password123') }
      let(:conversation) { Conversation.create!(sender: user1, recipient: user2) }
      let(:message) do
        msg = Message.new(conversation: conversation, user: user1, message_type: 'audio')
        msg.attachment.attach(
          io: StringIO.new('fake audio content'),
          filename: 'test_audio.mp3',
          content_type: 'audio/mp3'
        )
        msg.save!
        msg
      end

      it 'returns transcribed text result' do
        service = AiAudioTranscriptionService.new(message.attachment)
        result = service.transcribe

        expect(result[:success]).to be true
        expect(result[:text]).to be_present
      end
    end
  end
end
