require 'webmock/rspec'

WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['chromedriver.storage.googleapis.com', '127.0.0.1', 'localhost']
)

RSpec.configure do |config|
  config.before(:each) do
    stub_request(:post, /api\.groq\.com/)
      .to_return(lambda do |request|
        body_json = JSON.parse(request.body) rescue {}
        system_content = body_json.dig('messages', 0, 'content').to_s
        user_content = body_json.dig('messages', 1, 'content').to_s

        response_hash = if system_content.include?('Sangam Guard')
                          if user_content.match?(/kill yourself|hate|bitch/i)
                            {
                              "flagged" => true,
                              "toxicity_score" => 0.95,
                              "categories" => ["hate_speech"],
                              "action" => "blocked",
                              "reason" => "Contains severe abusive language."
                            }
                          else
                            {
                              "flagged" => false,
                              "toxicity_score" => 0.0,
                              "categories" => ["none"],
                              "action" => "approved",
                              "reason" => "Safe content."
                            }
                          end
                        elsif system_content.include?('Co-Writer') || system_content.include?('article')
                          if user_content.include?('outline') || system_content.include?('outline')
                            { "generated_content" => "### Section 1\nContent 1\n### Section 2\nContent 2" }
                          else
                            { "generated_content" => "Continuing the story with AI insight..." }
                          end
                        elsif system_content.include?('Reel Studio')
                          {
                            "slides" => [
                              { "headline" => "Slide 1", "caption" => "Script 1", "bg_gradient" => "linear-gradient(135deg, #6366f1, #a855f7)" },
                              { "headline" => "Slide 2", "caption" => "Script 2", "bg_gradient" => "linear-gradient(135deg, #3b82f6, #06b6d4)" },
                              { "headline" => "Slide 3", "caption" => "Script 3", "bg_gradient" => "linear-gradient(135deg, #ec4899, #f43f5e)" }
                            ]
                          }
                        elsif system_content.include?('Valuation') || system_content.include?('Marketplace')
                          {
                            "suggested_price" => 150.0,
                            "price_range" => { "min" => 120, "max" => 180 },
                            "reasoning" => "Fair market value based on condition.",
                            "accepted" => true,
                            "counter_offer" => 140.0
                          }
                        elsif system_content.include?('Smart Replies') || system_content.include?('replies')
                          { "replies" => ["Sounds great!", "Count me in!", "Let's do it!"] }
                        elsif system_content.include?('Translator')
                          { "translated_text" => "Hola amigo" }
                        else
                          {
                            "tags" => [{ "name" => "Technology", "confidence" => 0.95 }],
                            "text" => "Mocked AI response",
                            "caption" => "Mocked AI caption",
                            "summary" => "Mocked AI summary",
                            "sentiment" => "positive",
                            "html" => "<p>Mocked AI content</p>",
                            "generated_content" => "Mocked AI content",
                            "answer" => "Mocked AI answer"
                          }
                        end

        {
          status: 200,
          headers: { 'Content-Type' => 'application/json' },
          body: {
            choices: [
              {
                message: {
                  content: response_hash.is_a?(String) ? response_hash : response_hash.to_json
                }
              }
            ]
          }.to_json
        }
      end)

    stub_request(:post, /api\.openai\.com/)
      .to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: { choices: [{ message: { content: 'Mocked OpenAI response' } }] }.to_json
      )
  end
end
