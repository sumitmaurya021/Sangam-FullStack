class AiChatResponseJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    trigger_message = Message.find_by(id: message_id)
    return unless trigger_message

    conversation = trigger_message.conversation
    ai_bot = User.ai_bot

    # Fetch last 15 messages to build context
    history = conversation.messages.where(deleted: false).order(created_at: :asc).last(15)

    messages_payload = [
      {
        "role": "system",
        "content": (
          "You are 'AI Assistant ✨' inside a social media app called Sangam. "

          "You are highly adaptive, human-like, and dynamic. "
          "Always mirror the user's vibe, language, humor, energy, and conversation style naturally. "

          "If the user gives you a nickname or asks you to act as a girl, boy, friend, bestie, gamer, mentor, or any other persona, fully accept the role and stay in character naturally. "

          "You are fluent in all languages and dialects. "
          "CRITICAL: If the user writes in Romanized Hindi/Hinglish (e.g. 'kya kar rahe ho', 'bhai kya scene hai'), you MUST reply in natural, modern Indian Hinglish exactly like real people chat. "
          "Never use overly formal Hindi unless the user explicitly asks for it. "

          "Match the user's style. "
          "If they are funny, be funny. "
          "If they are serious, be serious. "
          "If they are sarcastic, respond with smart sarcasm. "

          "If the user is rude or abusive, do NOT generate hateful or harmful content. "
          "Instead, reply with witty, confident, playful, and assertive comebacks without escalating. "

          "Keep responses concise and conversational by default unless the user asks for detail. "

          "IMPORTANT RULES: "
          "Never output role-play actions, stage directions, or narration. "
          "Do NOT write text like '*nods slowly*', '*smiles*', '*laughs*', '*sighs*', '*looks at you*', '(laughs)', or similar expressions. "
          "Reply only with plain conversational text as if a real person is chatting. "

          "Avoid robotic phrases, unnecessary disclaimers, and repetitive sentences. "
          "Use emojis only when they naturally fit the user's vibe."
        )
      }
    ]

    history.each do |msg|
      role = (msg.user_id == ai_bot.id) ? "assistant" : "user"
      content = msg.body.to_s
      
      # Strip out any historical roleplay asterisks so the LLM doesn't learn from its own past mistakes
      if role == "assistant"
        content = content.gsub(/\*.*?\*/, '').gsub(/^\(.*?\)|\(.*?\}$/, '').strip
      end

      next if content.blank?

      messages_payload << { role: role, content: content }
    end

    api_key = ENV["GROQ_API_KEY"]
    return if api_key.blank?

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages_payload,
      "temperature" => 0.7
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      ai_reply = result.dig("choices", 0, "message", "content")

      if ai_reply.present?
        # Post-process to guarantee removal of any leaked roleplay asterisks like *smiles*
        clean_reply = ai_reply.gsub(/\*.*?\*/, '').gsub(/^\(.*?\)|\(.*?\}$/, '').strip

        # In case the cleaning removed everything, fallback to the original (rare, but safe)
        clean_reply = ai_reply.strip if clean_reply.blank?

        Message.create!(
          conversation: conversation,
          user: ai_bot,
          body: clean_reply,
          message_type: "text"
        )
      end
    else
      Rails.logger.error "AiChatResponseJob API Error: #{response.body}"
    end
  rescue StandardError => e
    Rails.logger.error "AiChatResponseJob Exception: #{e.message}"
  end
end
