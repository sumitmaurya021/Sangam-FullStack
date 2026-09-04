require "net/http"
require "uri"
require "json"

class AiModerationService
  # Fallback profanity and abuse regex patterns
  SEVERE_PATTERNS = /bitch|fuck|asshole|nigger|cunt|bastard|kill yourself|suicide|terrorist|hitler/i
  MILD_PATTERNS   = /shit|crap|damn|stupid|idiot|loser|scam|spam|fake/i

  def initialize(text, user: nil, target_type: nil, target_id: nil)
    @text = text.to_s.strip
    @user = user
    @target_type = target_type
    @target_id = target_id
  end

  def analyze
    return approved_result if @text.blank?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      ai_result = call_groq_api(api_key)
      if ai_result[:success]
        log = create_log(ai_result[:data])
        return {
          flagged: ai_result[:data]["flagged"] == true,
          action_taken: ai_result[:data]["action"],
          reason: ai_result[:data]["reason"],
          toxicity_score: ai_result[:data]["toxicity_score"],
          categories: ai_result[:data]["categories"],
          log: log
        }
      end
    end

    # Fallback heuristic evaluation
    heuristic_evaluate
  end

  private

  def call_groq_api(api_key)
    system_prompt = <<~PROMPT
      You are Sangam Guard, an expert real-time AI content moderation classifier.
      Your task is to analyze user text for toxicity, hate speech, harassment, severe profanity, cyberbullying, or illegal content.

      Respond ONLY with a valid JSON object with NO markdown formatting and NO code block wrappers.

      JSON Schema:
      {
        "flagged": true or false,
        "toxicity_score": number between 0.0 and 1.0,
        "categories": ["array of matching category strings like hate_speech, harassment, profanity, violence, spam, scam, sexual, none"],
        "action": "blocked" (if toxicity_score >= 0.70 or severe hate/violence), "flagged_for_review" (if toxicity_score >= 0.40), or "approved" (if safe),
        "reason": "Short 1-sentence explanation of why it was flagged or approved."
      }
    PROMPT

    messages = [
      { role: "system", content: system_prompt },
      { role: "user", content: @text }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.1,
      "max_completion_tokens" => 200
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      res_body = JSON.parse(response.body)
      raw_content = res_body.dig("choices", 0, "message", "content").to_s
      cleaned = raw_content.gsub(/```json/i, "").gsub(/```/, "").strip
      data = JSON.parse(cleaned)
      { success: true, data: data }
    else
      Rails.logger.error("Groq Moderation API Error: #{response.body}")
      { success: false }
    end
  rescue => e
    Rails.logger.error("AiModerationService API call exception: #{e.message}")
    { success: false }
  end

  def heuristic_evaluate
    if @text.match?(SEVERE_PATTERNS)
      data = {
        "flagged" => true,
        "toxicity_score" => 0.90,
        "categories" => ["profanity", "harassment"],
        "action" => "blocked",
        "reason" => "Contains severe explicit/abusive language."
      }
    elsif @text.match?(MILD_PATTERNS)
      data = {
        "flagged" => true,
        "toxicity_score" => 0.50,
        "categories" => ["profanity"],
        "action" => "flagged_for_review",
        "reason" => "Contains potentially offensive or spam language."
      }
    else
      data = {
        "flagged" => false,
        "toxicity_score" => 0.0,
        "categories" => ["none"],
        "action" => "approved",
        "reason" => "Safe content."
      }
    end

    log = create_log(data)
    {
      flagged: data["flagged"],
      action_taken: data["action"],
      reason: data["reason"],
      toxicity_score: data["toxicity_score"],
      categories: data["categories"],
      log: log
    }
  end

  def create_log(data)
    AiModerationLog.create!(
      user: @user,
      target_type: @target_type,
      target_id: @target_id,
      content_snippet: @text.truncate(200),
      toxicity_score: data["toxicity_score"] || 0.0,
      flagged_categories: (data["categories"] || []).join(", "),
      action_taken: data["action"] || "approved",
      reason: data["reason"] || "Evaluated by AI Guard"
    )
  rescue => e
    Rails.logger.error("Failed to create AiModerationLog: #{e.message}")
    nil
  end

  def approved_result
    {
      flagged: false,
      action_taken: "approved",
      reason: "Empty content",
      toxicity_score: 0.0,
      categories: [],
      log: nil
    }
  end
end
