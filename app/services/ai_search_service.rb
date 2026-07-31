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

    query_vector = AiEmbeddingService.new(@query).generate

    # 1. Query database models (scoped safely)
    users = User.where.not(id: @current_user.id)
                .where("name ILIKE :q OR email ILIKE :q", q: "%#{@query}%")
                .order(:name)
                .limit(5)

    all_posts = Post.visible_to(@current_user).includes(:user).limit(25)
    posts_with_scores = all_posts.map do |p|
      v = p.try(:embedding) || p.try(:embedding_data)
      sim = AiEmbeddingService.cosine_similarity(query_vector, v)
      text_match = p.content.to_s.downcase.include?(@query.downcase)
      final_score = (sim * 0.7) + (text_match ? 0.3 : 0.0)
      [p, final_score]
    end.sort_by { |_, score| -score }.take(5)

    groups = Group.public_groups.search(@query).limit(5)

    events = Event.upcoming.search(@query).limit(5)

    all_articles = Article.published.includes(:user).limit(25)
    articles_with_scores = all_articles.map do |a|
      v = a.try(:embedding) || a.try(:embedding_data)
      sim = AiEmbeddingService.cosine_similarity(query_vector, v)
      text_match = a.title.to_s.downcase.include?(@query.downcase)
      final_score = (sim * 0.7) + (text_match ? 0.3 : 0.0)
      [a, final_score]
    end.sort_by { |_, score| -score }.take(5)

    all_listings = MarketplaceListing.active.limit(25)
    listings_with_scores = all_listings.map do |l|
      v = l.try(:embedding) || l.try(:embedding_data)
      sim = AiEmbeddingService.cosine_similarity(query_vector, v)
      text_match = l.title.to_s.downcase.include?(@query.downcase) || l.description.to_s.downcase.include?(@query.downcase)
      final_score = (sim * 0.7) + (text_match ? 0.3 : 0.0)
      [l, final_score]
    end.sort_by { |_, score| -score }.take(5)

    # 2. Serialize results for front-end preview cards
    serialized_results = {
      search_mode: "⚡ AI Vector Hybrid Search",
      users: users.map { |u|
        {
          id: u.id,
          name: u.name,
          avatar: u.avatar.attached? ? Rails.application.routes.url_helpers.url_for(u.avatar) : nil,
          profile_url: profile_path(u),
          mutual_friends_count: (@current_user.all_friends & u.all_friends).count
        }
      },
      posts: posts_with_scores.map { |p, score|
        {
          id: p.id,
          content: p.content.truncate(120),
          user: p.user.name,
          post_url: post_path(p),
          similarity_score: "#{(score * 100).round}% Match",
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
      articles: articles_with_scores.map { |a, score|
        {
          id: a.id,
          title: a.title,
          user: a.user.name,
          article_url: article_path(a),
          similarity_score: "#{(score * 100).round}% Match",
          views_count: a.views_count
        }
      },
      listings: listings_with_scores.map { |l, score|
        {
          id: l.id,
          title: l.title,
          price: l.price,
          category: l.category,
          condition: l.condition,
          similarity_score: "#{(score * 100).round}% Match",
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
    
    if posts_with_scores.any?
      context += "\nPOSTS:\n"
      posts_with_scores.each { |p, s| context += "- Post by #{p.user.name} (#{(s*100).round}% Match): \"#{p.content.truncate(100)}\" [Link: /posts/#{p.id}]\n" }
    end
    
    if groups.any?
      context += "\nGROUPS:\n"
      groups.each { |g| context += "- Group \"#{g.name}\" - #{g.description.to_s.truncate(80)} [Link: /groups/#{g.id}]\n" }
    end
    
    if events.any?
      context += "\nEVENTS:\n"
      events.each { |e| context += "- Event \"#{e.title}\" on #{e.starts_at.strftime("%b %d, %Y")} [Link: /events/#{e.id}]\n" }
    end

    if articles_with_scores.any?
      context += "\nARTICLES:\n"
      articles_with_scores.each { |a, s| context += "- Article \"#{a.title}\" (#{(s*100).round}% Match) by #{a.user.name} [Link: /articles/#{a.id}]\n" }
    end

    if listings_with_scores.any?
      context += "\nMARKETPLACE LISTINGS:\n"
      listings_with_scores.each { |l, s| context += "- Listing \"#{l.title}\" (#{(s*100).round}% Match) for #{l.formatted_price} [Link: /marketplace/#{l.id}]\n" }
    end

    if context.blank?
      context = "No direct matching database records found."
    end

    system_instructions = <<~PROMPT
      ############################################################
      ROLE
      ############################################################

      You are Sangam AI, the official intelligent search assistant for the Sangam social networking platform.

      Your purpose is to help users quickly understand search results returned from the Sangam database.

      You are NOT a general chatbot.

      Your knowledge for this response comes ONLY from the database context below.

      Never invent users, posts, groups, events, articles, marketplace listings, or links.

      ############################################################
      USER SEARCH
      ############################################################

      User Query:

      "#{@query}"

      ############################################################
      DATABASE RESULTS
      ############################################################

      #{context}

      ############################################################
      PRIMARY OBJECTIVE
      ############################################################

      Carefully analyze every database record.

      Understand what the user is searching for.

      Explain the results naturally.

      Help the user discover the most relevant content.

      ############################################################
      RESPONSE STYLE
      ############################################################

      Your response must be:

      • Friendly

      • Professional

      • Helpful

      • Conversational

      • Human

      • Concise

      • Easy to read

      Never sound robotic.

      ############################################################
      IF RESULTS EXIST
      ############################################################

      When matching records exist:

      • Begin with a short summary.

      • Mention the number of relevant results if possible.

      • Group similar items together.

      • Explain why each result matches the search.

      • Highlight the most relevant results first.

      • Never simply copy database text.

      • Summarize naturally.

      ############################################################
      LINKS
      ############################################################

      Every result mentioned MUST include its provided relative markdown link.

      Examples:

      [John Doe](/profile/12)

      [Rails Workshop](/events/7)

      [Ruby Beginners](/groups/4)

      [Marketplace Bike](/marketplace/9)

      Use ONLY the links provided inside the database context.

      Never create links.

      Never modify links.

      ############################################################
      IF NOTHING MATCHES
      ############################################################

      If there are no relevant records:

      Politely explain that nothing matching the search was found.

      Suggest trying:

      • different keywords

      • shorter keywords

      • broader keywords

      • alternative spellings

      • related topics

      Example suggestions:

      • users

      • groups

      • posts

      • events

      • marketplace listings

      • articles

      Never pretend results exist.

      ############################################################
      HALLUCINATION RULES
      ############################################################

      Never:

      • invent database records

      • invent profile names

      • invent posts

      • invent articles

      • invent events

      • invent groups

      • invent marketplace listings

      • invent URLs

      • guess missing information

      If information isn't in the database context,
      simply don't mention it.

      ############################################################
      MARKDOWN
      ############################################################

      Output clean Markdown.

      Use:

      • paragraphs

      • bullet lists when useful

      • markdown links

      Avoid:

      • HTML

      • tables

      • code blocks

      ############################################################
      LENGTH
      ############################################################

      Keep the response between 120 and 180 words.

      ############################################################
      FINAL QUALITY CHECK
      ############################################################

      Before responding internally verify:

      ✓ All information comes from the provided database context.

      ✓ Every mentioned item includes its original markdown link.

      ✓ No hallucinated content.

      ✓ Friendly and natural tone.

      ✓ Clean Markdown.

      ✓ Easy to read.

      ✓ Directly answers the user's search.

      ############################################################
      OUTPUT
      ############################################################

      Return ONLY the Markdown response.

      No explanations.

      No headings like "Search Results".

      No code blocks.

      No extra text.
    PROMPT

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
