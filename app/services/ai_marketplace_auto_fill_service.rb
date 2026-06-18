require "net/http"
require "uri"
require "json"

class AiMarketplaceAutoFillService
  def initialize(image_data_url)
    @image_data_url = image_data_url
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    return { success: false, error: "No image provided" } if @image_data_url.blank?

    messages = [
      {
        role: "user",
        content: [
          { type: "text", text: "You are an expert marketplace seller. Analyze this image of an item being sold. Generate a JSON object with exactly three keys: 'title' (a short, catchy title for the listing), 'description' (a detailed and appealing description of the item), and 'category' (you MUST choose exactly one from this list: electronics, furniture, clothing, vehicles, property, sports, books, toys, garden, other). Do not output any markdown formatting like ```json, just output the raw JSON object." },
          { type: "image_url", image_url: { url: @image_data_url } }
        ]
      }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "meta-llama/llama-4-scout-17b-16e-instruct",
      "messages" => messages,
      "temperature" => 0.5,
      "max_completion_tokens" => 500
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content") || ""
      
      # Clean up potential markdown formatting
      cleaned_content = content.gsub(/```json/i, "").gsub(/```/, "").strip
      
      begin
        parsed_json = JSON.parse(cleaned_content)
        { success: true, data: parsed_json }
      rescue JSON::ParserError => e
        Rails.logger.error("JSON Parsing Error in AiMarketplaceAutoFillService: #{e.message} - Raw content: #{content}")
        { success: false, error: "Failed to parse AI response as JSON" }
      end
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiMarketplaceAutoFillService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
