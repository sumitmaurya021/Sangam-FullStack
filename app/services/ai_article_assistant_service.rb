require "net/http"
require "uri"
require "json"

class AiArticleAssistantService
  def initialize(prompt)
    @prompt = prompt
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    return { success: false, error: "No prompt provided" } if @prompt.blank?

    messages = [
      {
        role: "system",
        content: "You are an expert ghostwriter and article assistant. Write a comprehensive, engaging article based on the user's prompt. IMPORTANT: Output the article in raw HTML format using basic tags like <h1>, <h2>, <p>, <strong>, <ul>, and <li>. Do NOT wrap the HTML in markdown code blocks like ```html ... ```. Just output the raw HTML directly so it can be inserted straight into a rich text editor."
      },
      {
        role: "user",
        content: "Topic/Prompt: \"#{@prompt}\""
      }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.7,
      "max_completion_tokens" => 2000
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      html_content = result.dig("choices", 0, "message", "content") || ""
      
      # Clean up potential markdown formatting that LLaMA might still include
      html_content = html_content.gsub(/```html/i, "").gsub(/```/, "").strip
      
      { success: true, html: html_content }
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiArticleAssistantService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
