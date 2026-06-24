require "net/http"
require "uri"
require "json"

class AiSearchService
  include Rails.application.routes.url_helpers

  def initialize(query, current_user)
    @query = query.to_s.strip
    @current_user = current_user
  end

  def generate
    return { success: false, error: "Query is blank" } if @query.blank?

    # 1. Query database models (scoped safely)
    users = User.where.not(id: @current_user.id)
                .where("name ILIKE :q OR email ILIKE :q", q: "%#{@query}%")
                .order(:name)
                .limit(5)

    posts = Post.visible_to(@current_user)
                .search(@query)
                .includes(:user)
                .order(created_at: :desc)
                .limit(5)

    groups = Group.public_groups.search(@query).limit(5)

    events = Event.upcoming.search(@query).limit(5)

    articles = Article.published
                      .where("title ILIKE ?", "%#{@query}%")
                      .includes(:user)
                      .order(created_at: :desc)
                      .limit(5)

    listings = MarketplaceListing.active.search(@query).limit(5)

    # 2. Serialize results for front-end preview cards
    serialized_results = {
      users: users.map { |u|
        {
          id: u.id,
          name: u.name,
          avatar: u.avatar.attached? ? Rails.application.routes.url_helpers.url_for(u.avatar) : nil,
          profile_url: profile_path(u),
          mutual_friends_count: (@current_user.all_friends & u.all_friends).count
        }
      },
      posts: posts.map { |p|
        {
          id: p.id,
          content: p.content.truncate(120),
          user: p.user.name,
          post_url: post_path(p),
          created_at: p.created_at.strftime("%b %d, %Y")
        }
      },
      groups: groups.map { |g|
        {
          id: g.id,
          name: g.name,
          description: g.description.to_s.truncate(80),
          members_count: g.members_count,
          group_url: group_path(g)
        }
      },
      events: events.map { |e|
        {
          id: e.id,
          title: e.title,
          description: e.description.to_s.truncate(80),
          starts_at: e.starts_at.strftime("%b %d, %Y at %I:%M %p"),
          event_url: event_path(e)
        }
      },
      articles: articles.map { |a|
        {
          id: a.id,
          title: a.title,
          user: a.user.name,
          article_url: article_path(a),
          views_count: a.views_count
        }
      },
      listings: listings.map { |l|
        {
          id: l.id,
          title: l.title,
          price: l.price,
          category: l.category,
          condition: l.condition,
          listing_url: marketplace_listing_path(l)
        }
      }
    }

    # 3. Create context string for Groq
    context = ""
    
    if users.any?
      context += "\nPEOPLE:\n"
      users.each { |u| context += "- #{u.name} (Email: #{u.email}) [Link: /profile/#{u.id}]\n" }
    end
    
    if posts.any?
      context += "\nPOSTS:\n"
      posts.each { |p| context += "- Post by #{p.user.name}: \"#{p.content.truncate(100)}\" [Link: /posts/#{p.id}]\n" }
    end
    
    if groups.any?
      context += "\nGROUPS:\n"
      groups.each { |g| context += "- Group \"#{g.name}\" - #{g.description.to_s.truncate(80)} [Link: /groups/#{g.id}]\n" }
    end
    
    if events.any?
      context += "\nEVENTS:\n"
      events.each { |e| context += "- Event \"#{e.title}\" on #{e.starts_at.strftime("%b %d, %Y")} [Link: /events/#{e.id}]\n" }
    end

    if articles.any?
      context += "\nARTICLES:\n"
      articles.each { |a| context += "- Article \"#{a.title}\" by #{a.user.name} [Link: /articles/#{a.id}]\n" }
    end

    if listings.any?
      context += "\nMARKETPLACE LISTINGS:\n"
      listings.each { |l| context += "- Listing \"#{l.title}\" for #{l.formatted_price} [Link: /marketplace/#{l.id}]\n" }
    end

    if context.blank?
      context = "No direct matching database records found."
    end

    system_instructions = <<~TEXT
      You are Sangam AI, a highly intelligent conversational search assistant for the 'Sangam' social network platform.
      The user searched for: "#{@query}"
      
      Here are the relevant database records matching the search query:
      #{context}

      Write a helpful, friendly response summarizing what was found and directly answering their search query.
      
      Guidelines:
      1. Address the user directly in a professional, natural, and friendly tone.
      2. If matching records exist, summarize them clearly and explain how they relate to the query.
      3. You MUST include markdown links to the matching items using the exact relative links provided in the context (e.g. [User Name](/profile/1), [Post by Writer](/posts/2), [Group Name](/groups/3), [Event Title](/events/4), [Article Title](/articles/5), [Listing Title](/marketplace/6)).
      4. If no records match, politely explain that nothing was found in the database and suggest keywords they could try (e.g. search for groups like 'Velo Coders', events like 'Rails Workshop', or other topics).
      5. Keep the response under 150-180 words.
      6. Output your response in clean Markdown.
    TEXT

    api_key = ENV["GROQ_API_KEY"]
    if api_key.blank?
      # Fallback response if API key is missing
      fallback_answer = "Sangam AI Search: Groq API Key is not set in the environment. Here are the database search results:\n\n"
      fallback_answer += "- **People**: " + users.map { |u| "[#{u.name}](/profile/#{u.id})" }.join(", ") + "\n" if users.any?
      fallback_answer += "- **Posts**: " + posts.map { |p| "[Post by #{p.user.name}](/posts/#{p.id})" }.join(", ") + "\n" if posts.any?
      fallback_answer += "- **Groups**: " + groups.map { |g| "[#{g.name}](/groups/#{g.id})" }.join(", ") + "\n" if groups.any?
      fallback_answer += "- **Events**: " + events.map { |e| "[#{e.title}](/events/#{e.id})" }.join(", ") + "\n" if events.any?
      fallback_answer += "- **Articles**: " + articles.map { |a| "[#{a.title}](/articles/#{a.id})" }.join(", ") + "\n" if articles.any?
      fallback_answer += "- **Listings**: " + listings.map { |l| "[#{l.title}](/marketplace/#{l.id})" }.join(", ") if listings.any?
      fallback_answer += "No matching items found. Please try a different query." if context == "No direct matching database records found."
      
      return { success: true, answer: fallback_answer, results: serialized_results }
    end

    messages = [
      { role: "system", content: system_instructions },
      { role: "user", content: "Query: \"#{@query}\"" }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"
    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.4,
      "max_completion_tokens" => 400
    })

    req_options = { use_ssl: uri.scheme == "https" }
    
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      res_body = JSON.parse(response.body)
      answer = res_body.dig("choices", 0, "message", "content")
      { success: true, answer: answer, results: serialized_results }
    else
      Rails.logger.error("Groq AI Search error: #{response.body}")
      { success: false, error: "AI search service failed" }
    end
  rescue => e
    Rails.logger.error("AiSearchService error: #{e.message}\n#{e.backtrace.join("\n")}")
    { success: false, error: e.message }
  end
end
