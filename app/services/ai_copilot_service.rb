require "net/http"
require "uri"
require "json"

class AiCopilotService
  def initialize(prompt, current_user, context: {})
    @prompt = prompt.to_s.strip
    @current_user = current_user
    @context = context
  end

  def execute
    return { success: false, error: "Prompt is required" } if @prompt.blank?

    api_key = ENV["GROQ_API_KEY"]

    # Intent classifier & tool caller
    intent = detect_intent

    case intent[:action]
    when "create_post"
      handle_create_post(intent[:parameters])
    when "create_event"
      handle_create_event(intent[:parameters])
    when "search_marketplace"
      handle_search_marketplace(intent[:parameters])
    when "summarize_feed"
      handle_summarize_feed
    else
      handle_general_copilot_chat(api_key)
    end
  rescue => e
    Rails.logger.error("AiCopilotService error: #{e.message}\n#{e.backtrace.join("\n")}")
    { success: false, error: e.message }
  end

  private

  def detect_intent
    lower = @prompt.downcase

    if lower.match?(/\b(post|publish|write a post|share)\b/i) && !lower.include?("summarize")
      content = @prompt.gsub(/create post|write post|post|publish|share/i, "").strip
      content = @prompt if content.length < 3
      { action: "create_post", parameters: { content: content } }
    elsif lower.match?(/\b(event|meetup|schedule|party|conference)\b/i)
      { action: "create_event", parameters: { title: @prompt.truncate(50), description: @prompt } }
    elsif lower.match?(/\b(buy|sell|marketplace|product|listing|item|bike|laptop|phone)\b/i)
      { action: "search_marketplace", parameters: { query: @prompt } }
    elsif lower.match?(/\b(feed|summary|summarize|news|latest|what's happening)\b/i)
      { action: "summarize_feed", parameters: {} }
    else
      { action: "general_chat", parameters: {} }
    end
  end

  def handle_create_post(params)
    content = params[:content]
    if content.blank?
      return { success: false, answer: "What content would you like me to post for you?" }
    end

    post = @current_user.posts.create(content: content, visibility: "public")
    if post.persisted?
      {
        success: true,
        answer: "✨ Done! I have published a new post for you: \"#{content.truncate(80)}\"",
        action: { type: "post_created", post_id: post.id, post_url: "/posts" }
      }
    else
      { success: false, answer: "Could not create post: #{post.errors.full_messages.join(', ')}" }
    end
  end

  def handle_create_event(params)
    title = params[:title] || "Community Event"
    description = params[:description] || @prompt
    event = Event.create(
      organizer: @current_user,
      title: title,
      description: description,
      location: "Sangam Online Space",
      starts_at: 2.days.from_now,
      privacy: "public"
    )

    if event.persisted?
      {
        success: true,
        answer: "🗓️ I have scheduled your event **'#{event.title}'** for #{event.starts_at.strftime('%b %d, %Y')}.",
        action: { type: "event_created", event_id: event.id, event_url: "/events/#{event.id}" }
      }
    else
      { success: false, answer: "Failed to schedule event." }
    end
  end

  def handle_search_marketplace(params)
    listings = MarketplaceListing.active.search(params[:query]).limit(3)
    if listings.any?
      cards_text = listings.map { |l| "• **#{l.title}** (#{l.formatted_price}) - [View Listing](/marketplace/#{l.id})" }.join("\n")
      {
        success: true,
        answer: "🛒 Here are top marketplace items matching your query:\n\n#{cards_text}",
        action: { type: "marketplace_results" }
      }
    else
      {
        success: true,
        answer: "🛒 I checked the marketplace for '#{params[:query]}', but no active listings matched right now.",
        action: { type: "marketplace_empty" }
      }
    end
  end

  def handle_summarize_feed
    recent_posts = Post.visible_to(@current_user).recent.limit(5)
    if recent_posts.any?
      bullets = recent_posts.map { |p| "• **#{p.user.name}**: \"#{p.content.truncate(80)}\"" }.join("\n")
      {
        success: true,
        answer: "📰 **Here is your Sangam Feed Summary:**\n\n#{bullets}",
        action: { type: "feed_summary" }
      }
    else
      {
        success: true,
        answer: "📰 Your feed is currently quiet. Be the first to share an update!",
        action: { type: "feed_summary" }
      }
    end
  end

  def handle_general_copilot_chat(api_key)
    if api_key.blank?
      return {
        success: true,
        answer: "👋 Hi #{@current_user.name}! I am Sangam Genius AI. I can post updates, schedule events, summarize your feed, or search marketplace items for you!",
        action: { type: "general_chat" }
      }
    end

    system_instructions = <<~PROMPT
      You are Sangam Genius, the official AI Copilot inside the Sangam Social Platform.
      Help user #{@current_user.name} perform actions, navigate feeds, write content, and get answers.
      Be concise, helpful, friendly, and human-like.
    PROMPT

    messages = [
      { role: "system", content: system_instructions },
      { role: "user", content: @prompt }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.6,
      "max_completion_tokens" => 250
    })

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      res_body = JSON.parse(response.body)
      answer = res_body.dig("choices", 0, "message", "content")
      { success: true, answer: answer, action: { type: "general_chat" } }
    else
      { success: true, answer: "Hello! How can I assist you on Sangam today?" }
    end
  end
end
