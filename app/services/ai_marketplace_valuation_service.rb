require "net/http"
require "uri"
require "json"

class AiMarketplaceValuationService
  def initialize(listing_params = {})
    @title = listing_params[:title].to_s.strip
    @category = listing_params[:category].to_s.strip
    @condition = listing_params[:condition].to_s.strip
    @description = listing_params[:description].to_s.strip
    @price = listing_params[:price].to_f
  end

  def estimate_price
    return { success: false, error: "Title and Category are required for valuation" } if @title.blank?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      prompt = <<~PROMPT
        You are a top commercial marketplace price valuation AI.
        Estimate the fair market value range for the following item:
        Item Title: #{@title}
        Category: #{@category}
        Condition: #{@condition}
        Description: #{@description}

        Return ONLY a JSON object in this exact format:
        {
          "min_price": 200,
          "max_price": 260,
          "suggested_price": 230,
          "valuation_label": "Fair Market Price",
          "reasoning": "Based on recent category market trends for #{@condition} condition."
        }
      PROMPT

      uri = URI("https://api.groq.com/openai/v1/chat/completions")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
        "model" => "llama-3.1-8b-instant",
        "messages" => [{ role: "user", content: prompt }],
        "temperature" => 0.2,
        "response_format" => { type: "json_object" }
      })

      req_options = { use_ssl: uri.scheme == "https" }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        res_body = JSON.parse(response.body)
        content = res_body.dig("choices", 0, "message", "content")
        json = JSON.parse(content) rescue nil
        if json && json["suggested_price"]
          return {
            success: true,
            min_price: json["min_price"].to_f,
            max_price: json["max_price"].to_f,
            suggested_price: json["suggested_price"].to_f,
            valuation_label: json["valuation_label"] || "Fair Market Price",
            reasoning: json["reasoning"] || "Estimated from market trends"
          }
        end
      end
    end

    # Heuristic fallback valuation algorithm
    base_val = @price > 0 ? @price : 150.0
    case @condition
    when "new" then mult = 1.1
    when "like_new" then mult = 0.9
    when "good" then mult = 0.75
    when "fair" then mult = 0.55
    else mult = 0.4
    end

    suggested = (base_val * mult).round(2)
    {
      success: true,
      min_price: (suggested * 0.85).round(2),
      max_price: (suggested * 1.15).round(2),
      suggested_price: suggested,
      valuation_label: "Fair Market Price",
      reasoning: "Estimated based on category baseline and condition multiplier."
    }
  end

  def self.negotiate_offer(listing, buyer_offer_price)
    buyer_offer = buyer_offer_price.to_f
    list_price = listing.price.to_f

    if buyer_offer <= 0 || list_price <= 0
      return { status: "declined", message: "Invalid offer amount." }
    end

    min_acceptable = list_price * 0.80 # Accept up to 20% discount

    if buyer_offer >= list_price
      {
        status: "accepted",
        agreed_price: buyer_offer,
        message: "🎉 Fantastic! Offer of $#{'%.2f' % buyer_offer} matches or exceeds the listing price. Deal accepted!"
      }
    elsif buyer_offer >= min_acceptable
      {
        status: "accepted",
        agreed_price: buyer_offer,
        message: "✅ Great news! Seller's AI Assistant has accepted your offer of $#{'%.2f' % buyer_offer}!"
      }
    elsif buyer_offer >= (list_price * 0.65)
      counter_offer = ((buyer_offer + list_price) / 2.0).round(2)
      {
        status: "countered",
        counter_price: counter_offer,
        message: "🤝 Your offer of $#{'%.2f' % buyer_offer} is a bit low. Would you meet in the middle at $#{'%.2f' % counter_offer}?"
      }
    else
      {
        status: "declined",
        message: "❌ Offer of $#{'%.2f' % buyer_offer} is too low for this item condition. Minimum recommended offer is $#{'%.2f' % min_acceptable}."
      }
    end
  end
end
