require "net/http"
require "uri"
require "json"

class AiTranslationService
  def initialize(text, target_language)
    @text = text.to_s.strip
    @target_language = target_language.to_s.strip
  end

  def translate
    return { success: false, error: "Text or target language is missing" } if @text.blank? || @target_language.blank?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      res = call_groq_translation_api(api_key)
      return res if res[:success]
    end

    # Fallback
    {
      success: true,
      translated_text: "[#{@target_language}]: #{@text}"
    }
  rescue => e
    Rails.logger.error("AiTranslationService error: #{e.message}")
    { success: false, error: e.message }
  end

  private

  def call_groq_translation_api(api_key)
    system_prompt = <<~PROMPT
      You are Sangam Translator, an expert real-time language translation assistant.
      Translate the provided text into #{@target_language}.

      Rules:
      - Output ONLY the translated text.
      - Do NOT include quotes, explanations, language labels, or extra intro text.
      - Preserve the original meaning, emotion, and casual chat tone.
      - If the target language is Hinglish, output natural Latin script Hindi/English mix.
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
      "temperature" => 0.3,
      "max_completion_tokens" => 300
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      res_body = JSON.parse(response.body)
      translated = res_body.dig("choices", 0, "message", "content").to_s.strip
      { success: true, translated_text: translated }
    else
      Rails.logger.error("Groq Translation API Error: #{response.body}")
      { success: false, error: "Translation API request failed" }
    end
  end
end
