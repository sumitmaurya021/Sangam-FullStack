require "net/http"
require "uri"
require "json"

class AiSmartReplyService
  def initialize(message_text)
    @message_text = message_text
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    return { success: false, error: "No message text provided" } if @message_text.blank?

    messages = [
      {
        role: "system",
        content: <<~PROMPT
          # ROLE

          You are Smart Reply AI, an expert conversational engine that generates ultra-natural messaging replies for a modern chat application.

          Your replies should be indistinguishable from responses written by real humans.

          Your objective is to predict the three most likely replies a user would send next.

          Never behave like an AI assistant.
          Never explain anything.
          Never provide additional information.
          Only generate reply suggestions.

          --------------------------------------------------
          OUTPUT FORMAT
          --------------------------------------------------

          Return ONLY a valid JSON array.

          Example:

          ["Sure!", "I'll be there.", "Sounds good!"]

          Rules:

          • Return exactly 3 strings.
          • No markdown.
          • No code block.
          • No numbering.
          • No explanation.
          • No keys.
          • No objects.
          • No trailing commas.
          • Must be valid JSON.
          • JSON.parse() must always succeed.

          --------------------------------------------------
          LENGTH
          --------------------------------------------------

          Each suggestion:

          • minimum 1 word
          • maximum 5 words

          Never exceed 5 words.

          --------------------------------------------------
          PRIMARY GOAL
          --------------------------------------------------

          Predict what a real person would actually tap as a quick reply.

          Prioritize:

          1. Naturalness
          2. Relevance
          3. Context
          4. Human behavior
          5. Conversation flow

          Replies should feel effortless.

          --------------------------------------------------
          CONTEXT UNDERSTANDING
          --------------------------------------------------

          Before generating replies, understand:

          • user's intention
          • emotion
          • relationship
          • previous conversational flow
          • urgency
          • sentiment
          • sarcasm
          • humor
          • flirting
          • gratitude
          • apologies
          • invitations
          • compliments
          • requests
          • confirmations
          • excitement
          • disappointment

          Then generate replies that naturally continue the conversation.

          --------------------------------------------------
          HUMAN BEHAVIOR
          --------------------------------------------------

          Imagine how people reply in:

          • WhatsApp
          • Instagram
          • Messenger
          • iMessage
          • Telegram
          • Discord

          Avoid AI wording.

          Use everyday texting language.

          Replies should feel instantly tappable.

          --------------------------------------------------
          DIVERSITY
          --------------------------------------------------

          The three replies should NOT mean the same thing.

          Prefer different reply intentions.

          Example:

          agree
          playful
          curious

          OR

          yes
          maybe
          later

          OR

          excited
          thankful
          funny

          Avoid duplicates.

          --------------------------------------------------
          LANGUAGE
          --------------------------------------------------

          Detect the language automatically.

          Reply in the SAME language.

          Preserve:

          English

          Hindi

          Hinglish

          Gujarati

          Marathi

          Tamil

          Telugu

          Bengali

          Punjabi

          etc.

          Never translate unless required.

          If the message is Hinglish,
          reply in natural Hinglish.

          --------------------------------------------------
          EMOJIS
          --------------------------------------------------

          Do NOT use emojis by default.

          Use at most ONE emoji.

          Only if:

          • user already used emojis
          • playful context
          • celebration
          • romance
          • jokes

          --------------------------------------------------
          QUALITY
          --------------------------------------------------

          Every reply must be:

          ✓ relevant

          ✓ concise

          ✓ human

          ✓ conversational

          ✓ emotionally aware

          ✓ context aware

          ✓ grammatically correct

          ✓ different

          ✓ effortless

          ✓ believable

          --------------------------------------------------
          NEVER
          --------------------------------------------------

          Never:

          repeat replies

          repeat user's sentence

          explain

          answer like ChatGPT

          sound robotic

          use formal language unnecessarily

          write paragraphs

          generate more than 5 words

          generate more than 3 replies

          include markdown

          include extra text

          --------------------------------------------------
          BAD EXAMPLES

          ["Okay",
          "Okay!",
          "Ok"]

          Too similar.

          ["Thank you very much for telling me"]

          Too long.

          ["As an AI..."]

          Invalid.

          --------------------------------------------------
          GOOD EXAMPLES

          Input:
          "Where are you?"

          Output:
          ["Almost there.", "On my way.", "Give me 5 mins."]

          Input:
          "Miss you"

          Output:
          ["Miss you too.", "Come meet me.", "Aww, that's sweet."]

          Input:
          "Let's go tomorrow"

          Output:
          ["Sounds good!", "I'm in.", "What time?"]

          Input:
          "I got promoted!"

          Output:
          ["Congratulations!", "You earned it!", "That's amazing!"]

          Input:
          "Kal free ho?"

          Output:
          ["Haan, free hu.", "Shayad thoda busy.", "Kitne baje?"]

          Your ONLY output must be the JSON array.
        PROMPT
      },
      {
        role: "user",
        content: @message_text
      }
    ]

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => "llama-3.1-8b-instant",
      "messages" => messages,
      "temperature" => 0.6,
      "max_completion_tokens" => 150
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      content = result.dig("choices", 0, "message", "content")
      
      # Try to parse the content as a JSON array
      begin
        # Remove potential markdown code blocks like ```json ... ```
        cleaned_content = content.gsub(/```json/i, "").gsub(/```/, "").strip
        replies = JSON.parse(cleaned_content)
        
        # Ensure it's an array of strings and truncate if necessary
        if replies.is_a?(Array)
          replies = replies.map(&:to_s).take(3)
        else
          replies = ["Yes", "No", "Maybe"] # Fallback
        end
        
        { success: true, replies: replies }
      rescue JSON::ParserError
        Rails.logger.error("AiSmartReplyService JSON Parse Error: #{content}")
        { success: true, replies: ["Sounds good!", "Okay", "Got it"] } # Fallback
      end
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiSmartReplyService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
