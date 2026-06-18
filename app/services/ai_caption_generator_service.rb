require "net/http"
require "uri"
require "json"
require "base64"

class AiCaptionGeneratorService
  def initialize(image_file = nil)
    @image_file = image_file
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    messages = []

    if @image_file.present?
      base64_image = Base64.strict_encode64(@image_file.read)
      mime_type = @image_file.content_type || "image/jpeg"

      messages << {
        role: "user",
        content: [
          { type: "text", text: "Generate a creative and engaging social media caption for this image. Include some relevant hashtags. Write at least 50 words. VERY IMPORTANT: Output ONLY the caption and hashtags. Do not include any conversational text, introductions like 'Here is your caption', or explanations." },
          { type: "image_url", image_url: { url: "data:#{mime_type};base64,#{base64_image}" } }
        ]
      }
      model = "meta-llama/llama-4-scout-17b-16e-instruct"
    else
      messages << {
        role: "user",
        content: "Generate a creative, engaging, and slightly futuristic social media caption for a random post. Include some relevant hashtags. Write at least 50 words. VERY IMPORTANT: Output ONLY the caption and hashtags. Do not include any conversational text, quotes, introductions, or explanations."
      }
      model = "llama-3.1-8b-instant"
    end

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => model,
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
      caption = result.dig("choices", 0, "message", "content") || "Here is a cool post! 🚀 #vibes"
      # remove any surrounding quotes if generated
      caption = caption.strip.gsub(/^["']|["']$/, "")
      { success: true, caption: caption }
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiCaptionGeneratorService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
