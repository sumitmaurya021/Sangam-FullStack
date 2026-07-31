require "net/http"
require "json"

class DigitalTwinExecutionService
  def initialize(user:, trigger_source:, input_text:, sender_name: nil, conversation_id: nil, listing_id: nil)
    @user = user
    @twin = user.digital_twin
    @trigger_source = trigger_source
    @input_text = input_text.to_s.strip
    @sender_name = sender_name || "Guest"
    @conversation_id = conversation_id
    @listing_id = listing_id
  end

  def execute
    return { success: false, reason: "No active digital twin configured" } unless @twin&.enabled?

    unless @twin.should_trigger?(@trigger_source, recipient_online: @user.respond_to?(:online?) && @user.online?)
      return { success: false, reason: "Twin conditions not met for this trigger source" }
    end

    # Guardrail evaluation
    if @twin.violates_guardrails?(@input_text)
      log_execution(
        status: "blocked_by_guardrail",
        output_text: "Request contains sensitive or restricted topics prohibited by Digital Twin guardrails.",
        reason: "Guardrail triggered for input: #{@input_text.truncate(50)}"
      )
      return {
        success: false,
        blocked: true,
        reason: "Guardrail activated: request contains restricted topic."
      }
    end

    # Gather user context for RAG grounding
    user_context = build_user_context

    # Generate response via LLM
    response_text = generate_twin_response(user_context)

    if response_text.present?
      log_entry = log_execution(
        status: "executed",
        output_text: response_text
      )

      # Deliver reply if conversation_id is provided
      deliver_reply(response_text) if @conversation_id.present?

      {
        success: true,
        response: response_text,
        log_id: log_entry.id
      }
    else
      log_execution(
        status: "error",
        reason: "LLM generation returned empty response"
      )
      { success: false, reason: "Failed to generate AI response" }
    end
  end

  private

  def build_user_context
    recent_posts = @user.posts.order(created_at: :desc).limit(3).pluck(:content).join(" ")
    recent_articles = @user.articles.order(created_at: :desc).limit(2).pluck(:title).join(", ")

    context = []
    context << "User Name: #{@user.display_name}"
    context << "Persona Name: #{@twin.persona_name}"
    context << "Tone: #{@twin.tone.humanize}"
    context << "Custom Instructions: #{@twin.custom_instructions}" if @twin.custom_instructions.present?
    context << "Recent Posts Context: #{recent_posts.truncate(300)}" if recent_posts.present?
    context << "Published Articles: #{recent_articles}" if recent_articles.present?
    context.join("\n")
  end

  def generate_twin_response(context)
    api_key = ENV["GROK_API_KEY"].presence || ENV["GROQ_API_KEY"].presence
    
    prompt = <<~PROMPT
      You are an Autonomous Digital Twin AI proxy acting on behalf of #{@user.display_name}.
      Sender Name: #{@sender_name}
      Source: #{@trigger_source}

      User Profile & Context:
      #{context}

      Incoming Message/Inquiry from #{@sender_name}:
      "#{@input_text}"

      Instructions:
      1. Respond accurately, politely, and naturally as the Digital Twin representing #{@user.display_name}.
      2. Keep response concise (1-3 sentences).
      3. Clearly identify yourself as their Digital Twin proxy.
      4. Do NOT reveal private financial credentials or password data.
    PROMPT

    if api_key.present?
      fetch_grok_response(prompt, api_key)
    else
      fallback_response
    end
  end

  def fetch_grok_response(prompt, api_key)
    endpoint_url = ENV["GROK_API_KEY"].present? ? "https://api.x.ai/v1/chat/completions" : "https://api.groq.com/openai/v1/chat/completions"
    model_name = ENV["GROK_API_KEY"].present? ? "grok-beta" : "llama-3.3-70b-versatile"

    uri = URI(endpoint_url)
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "model" => model_name,
      "messages" => [
        { "role" => "system", "content" => "You are an autonomous Digital Twin AI assistant." },
        { "role" => "user", "content" => prompt }
      ],
      "temperature" => 0.7,
      "max_tokens" => 250
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      data.dig("choices", 0, "message", "content")&.strip || fallback_response
    else
      fallback_response
    end
  rescue StandardError => e
    Rails.logger.error("DigitalTwinExecutionService Grok API Error: #{e.message}")
    fallback_response
  end


  def fallback_response
    "Hello #{@sender_name}! I am #{@user.display_name}'s Digital Twin. They are currently away, but I've logged your message and notified them."
  end


  def deliver_reply(text)
    conversation = Conversation.find_by(id: @conversation_id)
    return unless conversation

    message = conversation.messages.create(
      user: @user,
      body: "[⚡ Digital Twin Reply] #{text}"
    )

    # Broadcast via ActionCable if available
    ActionCable.server.broadcast(
      "conversation_#{conversation.id}",
      {
        message_id: message.id,
        body: message.body,
        sender_id: @user.id,
        created_at: message.created_at.strftime("%I:%M %p")
      }
    ) rescue nil
  end

  def log_execution(status:, output_text: nil, reason: nil)
    @user.digital_twin_logs.create!(
      digital_twin: @twin,
      trigger_source: @trigger_source,
      sender_name: @sender_name,
      input_text: @input_text,
      output_text: output_text,
      status: status,
      reason: reason
    )
  end
end
