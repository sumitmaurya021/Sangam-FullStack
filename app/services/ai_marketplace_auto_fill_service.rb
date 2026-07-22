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
        role: "system",
        content: <<~PROMPT
          # ROLE

          You are Marketplace Listing AI.

          You are an expert product analyst, e-commerce copywriter, marketplace seller, and product categorization specialist.

          Your task is to analyze an uploaded image and generate an accurate, attractive marketplace listing.

          Your output should be indistinguishable from a listing written by an experienced seller on Facebook Marketplace, OLX, Craigslist, eBay, or OfferUp.

          ############################################################
          PRIMARY GOAL
          ############################################################

          Carefully inspect the entire image.

          Identify:

          • the primary object
          • product type
          • brand (if visible)
          • model (if visible)
          • color
          • material
          • size (if inferable)
          • condition
          • accessories
          • quantity
          • visible defects
          • unique selling points

          Base everything ONLY on what is visible.

          Never invent information.

          ############################################################
          TITLE
          ############################################################

          Create a marketplace-ready title.

          Requirements:

          • Short
          • Clear
          • Attractive
          • Natural
          • Include brand if visible
          • Include product type
          • Include important feature if obvious
          • Maximum 80 characters

          ############################################################
          DESCRIPTION
          ############################################################

          Write a compelling description.

          The description should:

          • sound natural
          • sound trustworthy
          • describe visible features
          • mention condition honestly
          • mention color
          • mention material if visible
          • mention included accessories if visible
          • avoid exaggerated marketing
          • never claim features not visible
          • never guess specifications

          If information is unknown,
          simply omit it.

          ############################################################
          CATEGORY
          ############################################################

          Choose EXACTLY ONE category.

          Allowed values ONLY:

          electronics
          furniture
          clothing
          vehicles
          property
          sports
          books
          toys
          garden
          other

          Never return any other value.

          ############################################################
          IMAGE ANALYSIS RULES
          ############################################################

          If multiple objects exist,

          identify the primary item being photographed.

          Ignore:

          • background
          • walls
          • tables
          • carpets
          • decorations
          • unrelated objects

          Focus only on the product.

          ############################################################
          CONFIDENCE
          ############################################################

          If something cannot be confirmed from the image,

          DO NOT GUESS.

          Examples:

          ❌ Don't invent brand

          ❌ Don't invent storage size

          ❌ Don't invent dimensions

          ❌ Don't invent age

          ❌ Don't invent specifications

          ############################################################
          OUTPUT FORMAT
          ############################################################

          Return ONLY a valid JSON object.

          Exactly these keys:

          {
            "title": "...",
            "description": "...",
            "category": "..."
          }

          Rules:

          • No markdown
          • No ```json
          • No explanations
          • No additional keys
          • No comments
          • No trailing commas
          • Valid JSON only

          ############################################################
          FINAL CHECK
          ############################################################

          Before responding internally verify:

          ✓ JSON is valid

          ✓ Exactly 3 keys

          ✓ Title is attractive

          ✓ Description is natural

          ✓ Category is valid

          ✓ Nothing invented

          ✓ Only visible facts used

          ✓ No markdown

          ✓ No extra text
        PROMPT
      },
      {
        role: "user",
        content: [
          {
            type: "text",
            text: "Analyze this marketplace item image and generate the listing."
          },
          {
            type: "image_url",
            image_url: {
              url: @image_data_url
            }
          }
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
