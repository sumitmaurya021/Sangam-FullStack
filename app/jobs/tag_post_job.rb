class TagPostJob < ApplicationJob
  queue_as :default

  def perform(post_id)
    post = Post.find_by(id: post_id)
    return unless post

    api_key = ENV["GROQ_API_KEY"]
    return if api_key.blank?

    categories = CategoryTag.all.pluck(:name)
    return if categories.empty?

    # Prepare content for LLM
    text_content = post.content.to_s.strip
    if text_content.blank? && post.image.attached?
      # If we had a vision key in the future, we could use it. For now, skip if no text.
      return
    end
    
    return if text_content.blank?

    prompt = <<~PROMPT
      You are an AI tagging engine for a social media app. 
      Analyze the following text and assign 1 to 3 relevant categories from this exact list:
      [#{categories.join(', ')}]
      
      Output ONLY a valid JSON array of objects with "name" (must exactly match a category from the list) and "confidence" (float between 0.0 and 1.0).
      Example: [{"name": "Technology", "confidence": 0.95}]
    PROMPT

    messages = [
      { role: "system", content: prompt },
      { role: "user", content: text_content }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.1,
      "response_format" => { "type" => "json_object" } # Groq supports json_object, but we asked for an array. Let's wrap it in an object.
    })

    # Wait, let's fix prompt for JSON object
    prompt = <<~PROMPT
      You are an AI tagging engine for a social media app. 
      Analyze the following text and assign 1 to 3 relevant categories from this exact list:
      [#{categories.join(', ')}]
      
      Output ONLY a valid JSON object with a key "tags" containing an array of objects with "name" (must exactly match a category from the list) and "confidence" (float between 0.0 and 1.0).
      Example: {"tags": [{"name": "Technology", "confidence": 0.95}]}
    PROMPT

    messages = [
      { role: "system", content: prompt },
      { role: "user", content: text_content }
    ]
    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.1,
      "response_format" => { "type" => "json_object" }
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content")
      parsed_json = JSON.parse(content) rescue {}
      
      tags = parsed_json["tags"] || []
      tags.each do |tag_data|
        name = tag_data["name"]
        conf = tag_data["confidence"].to_f
        
        category = CategoryTag.find_by(name: name)
        if category && conf > 0.3
          PostCategoryTag.find_or_create_by!(post: post, category_tag: category) do |pct|
            pct.confidence_score = conf
          end
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "TagPostJob Error for Post #{post_id}: #{e.message}"
  end
end
