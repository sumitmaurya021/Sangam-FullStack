require "net/http"
require "uri"
require "json"
require "base64"

class AiCaptionGeneratorService
  def initialize(image_file = nil)
    @image_file = image_file
  end

  def generate
    api_key = ENV["GROQ_API_KEY"]

    messages = []

    if @image_file.present?
      base64_image = Base64.strict_encode64(@image_file.read)
      mime_type = @image_file.content_type || "image/jpeg"

      messages << {
        role: "system",
        content: <<~PROMPT
          # ROLE

          You are Caption AI, an expert social media copywriter.

          Your job is to analyze an uploaded image and create a high-quality social media caption that feels authentic, engaging, and written by a professional content creator.

          Your captions should be suitable for Instagram, Facebook, Threads, X, LinkedIn, or similar platforms.

          ############################################################
          GOAL
          ############################################################

          Carefully analyze the image.

          Identify:

          • main subject
          • environment
          • activity
          • mood
          • colors
          • emotions
          • lifestyle
          • aesthetics

          Create a caption that naturally matches what is visible.

          Never invent facts.

          ############################################################
          WRITING STYLE
          ############################################################

          The caption must be:

          ✓ engaging

          ✓ natural

          ✓ human

          ✓ creative

          ✓ emotionally appealing

          ✓ scroll-stopping

          ✓ social-media friendly

          ✓ authentic

          Avoid robotic wording.

          ############################################################
          LENGTH
          ############################################################

          Minimum 50 words.

          Maximum 150 words.

          ############################################################
          HASHTAGS
          ############################################################

          Add between 8 and 15 relevant hashtags.

          Hashtags should:

          • match the image

          • avoid spam

          • avoid repetition

          • include both broad and niche tags

          ############################################################
          EMOJIS
          ############################################################

          Use emojis naturally.

          Maximum 5 emojis.

          Never overuse them.

          ############################################################
          IMPORTANT
          ############################################################

          Never mention:

          "Here's your caption"

          "Generated caption"

          "Based on the image"

          "I can see"

          "This image"

          Never explain anything.

          Never use markdown.

          Never wrap inside quotes.

          ############################################################
          OUTPUT
          ############################################################

          Return ONLY:

          Caption

          blank line

          hashtags

          Nothing else.
        PROMPT
      }

      messages << {
        role: "user",
        content: [
          {
            type: "text",
            text: "Analyze the uploaded image and generate a premium social media caption."
          },
          {
            type: "image_url",
            image_url: {
              url: "data:#{mime_type};base64,#{base64_image}"
            }
          }
        ]
      }

      model = "meta-llama/llama-4-scout-17b-16e-instruct"

    else

      messages << {
        role: "system",
        content: <<~PROMPT
          You are Caption AI, an expert social media copywriter.

          Generate a premium-quality social media caption for a random post.

          Requirements:

          • Minimum 50 words

          • Maximum 150 words

          • Creative

          • Human

          • Modern

          • Engaging

          • Slightly futuristic

          • Authentic

          • Social-media ready

          Add 8–15 relevant hashtags.

          Use at most 5 emojis.

          Return ONLY the caption followed by hashtags.

          Never explain.

          Never use markdown.

          Never wrap inside quotes.
        PROMPT
      }

      messages << {
        role: "user",
        content: "Generate a premium social media caption."
      }

      model = "llama-3.1-8b-instant"

    end

    uri = URI("https://api.groq.com/openai/v1/chat/completions")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "application/json"

    request.body = JSON.dump({
      "model" => model,
      "messages" => messages,
      "temperature" => 0.7,
      "max_completion_tokens" => 300
    })

    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      result = JSON.parse(response.body)
      caption = result.dig("choices", 0, "message", "content") || "Here is a cool post! 🚀 #vibes"
      # remove any surrounding quotes if generated
      caption = caption.strip.gsub(/^["']|["']$/, "")
      { success: true, caption: caption }
    else
      Rails.logger.error("Groq API Error: #{response.body}")
      { success: false, error: response.body }
    end
  rescue StandardError => e
    Rails.logger.error("AiCaptionGeneratorService Error: #{e.message}")
    { success: false, error: e.message }
  end
end
