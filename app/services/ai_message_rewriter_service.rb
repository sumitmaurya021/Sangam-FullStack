require "net/http"
require "uri"
require "json"

class AiMessageRewriterService
  def initialize(text, tone)
    @text = text
    @tone = tone
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    return { success: false, error: "Text is empty" } if @text.blank?
    return { success: false, error: "Tone is missing" } if @tone.blank?

    messages = [
      {
        role: "system",
        content: "You are an AI assistant that helps users rewrite their text messages. Your job is to take the user's message and rewrite it in a '#{@tone}' tone. \n\nIMPORTANT RULES:\n1. Preserve the original meaning and core information.\n2. Do NOT add any conversational fillers like 'Here is your rewritten message:' or 'Sure!'.\n3. Output ONLY the final rewritten text."
      },
      {
        role: "user",
        content: @text
      }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.7,
      "max_completion_tokens" => 300
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      rewritten_text = result.dig("choices", 0, "message", "content") || ""
      { success: true, text: rewritten_text.strip }
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiMessageRewriterService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
