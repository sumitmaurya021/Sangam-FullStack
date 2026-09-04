require 'rails_helper'

RSpec.describe AiCopilotService do
  describe '#execute' do
    let(:user) { User.create!(name: 'Copilot Tester', email: "copilot_#{SecureRandom.hex(4)}@test.com", password: 'password123') }

    context 'with post creation prompt' do
      it 'creates a new post and returns success answer' do
        service = AiCopilotService.new('Write a post about launching a new project', user)
        result = service.execute

        expect(result[:success]).to be true
        expect(result[:answer]).to include('published a new post')
        expect(result[:action][:type]).to eq('post_created')
        expect(user.posts.count).to eq(1)
      end
    end

    context 'with event creation prompt' do
      it 'schedules a new event' do
        service = AiCopilotService.new('Schedule a meetup event next Friday', user)
        result = service.execute

        expect(result[:success]).to be true
        expect(result[:answer]).to include('scheduled your event')
        expect(Event.where(organizer: user).count).to eq(1)
      end
    end

    context 'with feed summary prompt' do
      it 'summarizes recent feed posts' do
        Post.create!(user: user, content: 'Hello world feed item')
        service = AiCopilotService.new('Summarize my feed', user)
        result = service.execute

        expect(result[:success]).to be true
        expect(result[:answer]).to include('Feed Summary')
      end
    end

    context 'with general question prompt' do
      it 'returns conversational answer' do
        service = AiCopilotService.new('Hello Genius, what can you do?', user)
        result = service.execute

        expect(result[:success]).to be true
        expect(result[:answer]).to be_present
      end
    end
  end
end
