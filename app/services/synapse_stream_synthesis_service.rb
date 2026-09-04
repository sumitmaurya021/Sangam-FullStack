require "net/http"
require "json"

class SynapseStreamSynthesisService
  def initialize(synapse_stream)
    @stream = synapse_stream
    @user = synapse_stream.user
    @input_text = (synapse_stream.raw_input_text.presence || synapse_stream.audio_transcription).to_s.strip
  end

  def synthesize!
    return false if @input_text.blank?

    api_key = ENV["GROK_API_KEY"].presence || ENV["GROQ_API_KEY"].presence
    
    prompt = <<~PROMPT
      You are Synapse-Stream, an advanced Cross-Modal AI Content Synthesis Engine.
      Analyze the raw input seed concept below and simultaneously generate 4 structured content formats in strict valid JSON format.

      RAW SEED CONCEPT:
      "#{@input_text}"

      STRICT JSON OUTPUT FORMAT REQUIREMENTS:
      Return a single valid JSON object with the following exact keys:
      {
        "article": {
          "title": "Compelling Catchy Article Title",
          "subtitle": "Engaging Subtitle",
          "body": "<p>Detailed rich HTML article content with headings and paragraphs based on the seed concept.</p>"
        },
        "reel": {
          "title": "High-Energy Reel Title",
          "hooks": "Opening 3-second hook line",
          "script": "Full spoken voiceover script",
          "scenes": ["0-3s: Visual setup", "3-10s: Main demonstration", "10-15s: Call to action"]
        },
        "post": {
          "content": "Engaging social media post text formatted with emojis.",
          "hashtags": ["#Innovate", "#ContentCreator", "#Sangam"]
        },
        "marketplace": {
          "has_selling_intent": false,
          "title": "Listing Item Title",
          "price": 50.0,
          "description": "Item description and condition details",
          "category": "Electronics"
        }
      }

      Return ONLY the JSON object. Do not include markdown formatting codeblocks.
    PROMPT

    json_result = if api_key.present?
                    fetch_grok_json(prompt, api_key)
                  else
                    fallback_synthesis
                  end

    if json_result.is_a?(Hash) && json_result["article"].present?
      @stream.update!(
        synthesized_article_data: json_result["article"] || {},
        synthesized_reel_data: json_result["reel"] || {},
        synthesized_post_data: json_result["post"] || {},
        synthesized_marketplace_data: json_result["marketplace"] || {},
        status: "synthesized"
      )
      true
    else
      fallback_and_save
      true
    end
  rescue StandardError => e
    Rails.logger.error("SynapseStreamSynthesisService Error: #{e.message}")
    fallback_and_save
    false
  end

  private

  def fetch_grok_json(prompt, api_key)
    endpoint_url = ENV["GROK_API_KEY"].present? ? "https://api.x.ai/v1/chat/completions" : "https://api.groq.com/openai/v1/chat/completions"
    model_name = ENV["GROK_API_KEY"].present? ? "grok-beta" : "llama-3.3-70b-versatile"

    uri = URI(endpoint_url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "model" => model_name,
      "messages" => [
        { "role" => "system", "content" => "You are a JSON synthesis AI engine. Respond ONLY in valid raw JSON." },
        { "role" => "user", "content" => prompt }
      ],
      "temperature" => 0.7,
      "max_tokens" => 1200,
      "response_format" => { "type" => "json_object" }
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      raw_text = data.dig("choices", 0, "message", "content")&.strip
      parse_json(raw_text)
    else
      fallback_synthesis
    end
  rescue StandardError => e
    Rails.logger.error("SynapseStreamSynthesisService Grok JSON error: #{e.message}")
    fallback_synthesis
  end


  def parse_json(text)
    return fallback_synthesis if text.blank?
    clean_text = text.gsub(/^```json\s*/, '').gsub(/```$/, '').strip
    JSON.parse(clean_text)
  rescue StandardError
    fallback_synthesis
  end

  def fallback_synthesis
    {
      "article" => {
        "title" => "Exploring #{@input_text.truncate(30)}",
        "subtitle" => "A deep dive into cross-modal ideas",
        "body" => "<p>#{@input_text}</p><p>This article was auto-synthesized by Synapse-Stream to transform raw ideas into published content.</p>"
      },
      "reel" => {
        "title" => "Quick Reel: #{@input_text.truncate(20)}",
        "hooks" => "Did you know this about #{@input_text.truncate(15)}?",
        "script" => "Here is a quick breakdown of #{@input_text}. Share your thoughts in the comments!",
        "scenes" => ["0-3s: Hook camera angle", "3-10s: Visual overlay", "10-15s: Call to action"]
      },
      "post" => {
        "content" => "🚀 Excited to share new thoughts on: #{@input_text} ✨ #Sangam #Innovation",
        "hashtags" => ["#Sangam", "#CrossModal", "#Creator"]
      },
      "marketplace" => {
        "has_selling_intent" => false,
        "title" => "Featured Item for #{@input_text.truncate(20)}",
        "price" => 49.99,
        "description" => "Item related to #{@input_text}",
        "category" => "General"
      }
    }
  end

  def fallback_and_save
    data = fallback_synthesis
    @stream.update!(
      synthesized_article_data: data["article"],
      synthesized_reel_data: data["reel"],
      synthesized_post_data: data["post"],
      synthesized_marketplace_data: data["marketplace"],
      status: "synthesized"
    )
  end
end
