require "net/http"
require "uri"
require "json"

class AiSmartReplyService
  def initialize(message_text)
    @message_text = message_text
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    return { success: false, error: "No message text provided" } if @message_text.blank?

    messages = [
      {
        role: "system",
        content: "You are a smart reply assistant for a chat application. Given a message, provide exactly 3 distinct, short, and casual reply suggestions. Each suggestion must be a maximum of 5 words. Output your response as a raw JSON array of strings. Do not include any other text, markdown formatting, or explanations."
      },
      {
        role: "user",
        content: "Message: \"#{@message_text}\""
      }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.6,
      "max_completion_tokens" => 150
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content")
      
      # Try to parse the content as a JSON array
      begin
        # Remove potential markdown code blocks like ```json ... ```
        cleaned_content = content.gsub(/```json/i, "").gsub(/```/, "").strip
        replies = JSON.parse(cleaned_content)
        
        # Ensure it's an array of strings and truncate if necessary
        if replies.is_a?(Array)
          replies = replies.map(&:to_s).take(3)
        else
          replies = ["Yes", "No", "Maybe"] # Fallback
        end
        
        { success: true, replies: replies }
      rescue JSON::ParserError
        Rails.logger.error("AiSmartReplyService JSON Parse Error: #{content}")
        { success: true, replies: ["Sounds good!", "Okay", "Got it"] } # Fallback
      end
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiSmartReplyService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
