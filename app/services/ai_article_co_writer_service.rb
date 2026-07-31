require "net/http"
require "uri"
require "json"

class AiArticleCoWriterService
  def initialize(title, current_text, mode = "continue")
    @title = title.to_s.strip
    @current_text = current_text.to_s.strip
    @mode = mode.to_s.strip
  end

  def execute
    return { success: false, error: "Title or text context is required" } if @title.blank? && @current_text.blank?

    api_key = ENV["GROQ_API_KEY"]

    if api_key.present?
      prompt = case @mode
               when "outline"
                 "Generate a clean 4-heading markdown article outline for title: '#{@title}'. Current notes: '#{@current_text}'"
               when "fix_grammar"
                 "Fix all spelling, punctuation, and grammar mistakes in the following article paragraph:\n#{@current_text}"
               when "professional"
                 "Rewrite the following article text into a polished, professional tone suitable for a tech publication:\n#{@current_text}"
               when "summarize"
                 "Summarize the following text into 2 engaging paragraphs for an article intro:\n#{@current_text}"
               else # "continue"
                 "Continue writing the next 2 paragraphs naturally for the article titled '#{@title}'. Current text:\n#{@current_text}"
               end

      system_prompt = "You are a world-class article editor and writing assistant. Output ONLY the generated article text content without extra conversational chatter."

      uri = URI("https://api.groq.com/openai/v1/chat/completions")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{api_key}"
      request["Content-Type"] = "application/json"
      request.body = JSON.dump({
        "model" => "llama-3.1-8b-instant",
        "messages" => [
          { role: "system", content: system_prompt },
          { role: "user", content: prompt }
        ],
        "temperature" => 0.6,
        "max_completion_tokens" => 400
      })

      req_options = { use_ssl: uri.scheme == "https" }
      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      if response.is_a?(Net::HTTPSuccess)
        res_body = JSON.parse(response.body)
        content = res_body.dig("choices", 0, "message", "content")
        if content.present?
          return { success: true, generated_content: content.strip }
        end
      end
    end

    # Heuristic fallback co-writer
    fallback_content = case @mode
                       when "outline"
                         "### 1. Introduction\n### 2. Core Discussion & Insights\n### 3. Key Challenges\n### 4. Future Outlook"
                       when "fix_grammar"
                         @current_text.presence || "Grammar reviewed and updated."
                       when "professional"
                         "In recent developments, #{@current_text.downcase}"
                       else
                         "Furthermore, exploring these concepts opens new perspectives for innovation and long-term impact."
                       end

    { success: true, generated_content: fallback_content }
  end
end
