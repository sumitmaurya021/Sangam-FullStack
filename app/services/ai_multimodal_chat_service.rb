require "net/http"
require "uri"
require "json"

class AiMultimodalChatService
  def initialize(params = {})
    @messages = params[:messages] || []
    @text = params[:text].to_s.strip
    @tone = params[:tone].to_s.strip
  end

  def summarize_conversation
    return { success: false, error: "No messages provided for summarization" } if @messages.empty?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      prompt = <<~PROMPT
        Summarize the following chat conversation transcript into 3 concise bullet points.
        Transcript:
        #{@messages.join("\n")} 

        Return ONLY a JSON object:
        {
          "summary_bullets": ["Bullet 1", "Bullet 2", "Bullet 3"],
          "sentiment": "positive/neutral/urgent"
        }
      PROMPT

      uri = URI("https://api.groq.com/openai/v1/chat/completions")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
        "model" => "llama-3.1-8b-instant",
        "messages" => [{ role: "user", content: prompt }],
        "temperature" => 0.3,
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
        if json && json["summary_bullets"]
          return {
            success: true,
            summary: json["summary_bullets"].map { |b| "• #{b}" }.join("\n"),
            sentiment: json["sentiment"] || "neutral"
          }
        end
      end
    end

    # Heuristic fallback summary
    summary_lines = @messages.first(3).map { |m| "• #{m.to_s.truncate(70)}" }.join("\n")
    {
      success: true,
      summary: summary_lines.presence || "• Recent discussion updates",
      sentiment: "neutral"
    }
  end

  def rewrite_message
    return { success: false, error: "Text is required for rewriting" } if @text.blank?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      prompt = <<~PROMPT
        Rewrite the following text in a #{@tone.presence || 'polite and clear'} tone. Keep it concise.
        Text: #{@text}

        Return ONLY a JSON object:
        {
          "rewritten_text": "Your revised text here"
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
        if json && json["rewritten_text"]
          return { success: true, rewritten_text: json["rewritten_text"] }
        end
      end
    end

    # Fallback rewrite logic
    rewritten = case @tone
                when "formal" then "Dear friend, #{@text.downcase.capitalize}."
                when "casual" then "Hey! #{@text} 😊"
                when "shorten" then @text.truncate(40)
                else "Polite note: #{@text}"
                end

    { success: true, rewritten_text: rewritten }
  end
end
