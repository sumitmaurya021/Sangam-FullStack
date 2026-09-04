require "net/http"
require "uri"
require "json"

class AiReelStudioService
  GRADIENTS = [
    "linear-gradient(135deg, #6366f1, #a855f7)",
    "linear-gradient(135deg, #059669, #10b981)",
    "linear-gradient(135deg, #ec4899, #f43f5e)",
    "linear-gradient(135deg, #3b82f6, #1d4ed8)",
    "linear-gradient(135deg, #f59e0b, #d97706)"
  ].freeze

  def initialize(text, title = "")
    @text = text.to_s.strip
    @title = title.to_s.strip
  end

  def generate
    return { success: false, error: "Text content is required to generate reel" } if @text.blank?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      prompt = <<~PROMPT
        Convert the following article text into a 3-slide vertical story/reel script.
        Title: #{@title}
        Text: #{@text.truncate(1000)}

        Return ONLY a JSON object:
        {
          "reel_title": "Short catchy title",
          "slides": [
            { "headline": "Slide 1 Hook", "caption": "Short key point (max 15 words)" },
            { "headline": "Slide 2 Insight", "caption": "Core takeaway (max 15 words)" },
            { "headline": "Slide 3 Conclusion", "caption": "Call to action or final thought" }
          ]
        }
      PROMPT

      uri = URI("https://api.groq.com/openai/v1/chat/completions")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
        "model" => "llama-3.1-8b-instant",
        "messages" => [{ role: "user", content: prompt }],
        "temperature" => 0.4,
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
        if json && json["slides"]
          slides_with_bg = json["slides"].each_with_index.map do |s, idx|
            s.merge("bg_gradient" => GRADIENTS[idx % GRADIENTS.length])
          end

          return {
            success: true,
            reel_title: json["reel_title"] || @title.presence || "AI Generated Reel",
            slides: slides_with_bg
          }
        end
      end
    end

    # Heuristic fallback generator
    sentences = @text.split(/[.!?]+/).map(&:strip).reject(&:empty?)
    s1 = sentences[0] || "Key Insight"
    s2 = sentences[1] || "Core Highlight"
    s3 = sentences[2] || "Final Takeaway"

    fallback_slides = [
      { "headline" => "🔥 Key Highlight", "caption" => s1.truncate(80), "bg_gradient" => GRADIENTS[0] },
      { "headline" => "💡 Core Takeaway", "caption" => s2.truncate(80), "bg_gradient" => GRADIENTS[1] },
      { "headline" => "✨ Summary", "caption" => s3.truncate(80), "bg_gradient" => GRADIENTS[2] }
    ]

    {
      success: true,
      reel_title: @title.presence || "AI Reel Highlight",
      slides: fallback_slides
    }
  end
end
