class AiFeaturesController < ApplicationController
  before_action :authenticate_user!

  def generate_caption
    image = params[:image]
    service = AiCaptionGeneratorService.new(image)
    result = service.generate
    
    if result[:success]
      render json: { caption: result[:caption] }
    else
      render json: { error: "Failed to generate caption" }, status: :unprocessable_entity
    end
  end

  def generate_smart_replies
    conversation = current_user.conversations.find_by(id: params[:conversation_id])
    
    if conversation.nil?
      return render json: { error: "Conversation not found" }, status: :not_found
    end

    # Get the last message not sent by the current user
    last_message = conversation.messages.where.not(user_id: current_user.id).where(deleted: false).order(created_at: :desc).first

    if last_message.nil? || last_message.body.blank?
      return render json: { replies: ["Hi!", "How are you?", "Hey there!"] } # Fallback if no text message
    end

    service = AiSmartReplyService.new(last_message.body)
    result = service.generate

    if result[:success]
      render json: { replies: result[:replies] }
    else
      render json: { error: "Failed to generate replies" }, status: :unprocessable_entity
    end
  end

  def generate_article_content
    prompt = params[:prompt]
    
    if prompt.blank?
      return render json: { error: "Prompt is required" }, status: :unprocessable_entity
    end

    service = AiArticleAssistantService.new(prompt)
    result = service.generate

    if result[:success]
      render json: { html: result[:html] }
    else
      render json: { error: "Failed to generate article content" }, status: :unprocessable_entity
    end
  end

  def auto_fill_listing
    image_data_url = params[:image_data_url]
    
    if image_data_url.blank?
      return render json: { error: "Image data URL is required" }, status: :unprocessable_entity
    end

    service = AiMarketplaceAutoFillService.new(image_data_url)
    result = service.generate

    if result[:success]
      render json: result[:data]
    else
      render json: { error: result[:error] || "Failed to auto-fill listing" }, status: :unprocessable_entity
    end
  end

  def rewrite_message
    text = params[:text]
    tone = params[:tone] || "formal"

    if text.blank?
      return render json: { error: "Text is required" }, status: :unprocessable_entity
    end

    service = AiMultimodalChatService.new(text: text, tone: tone)
    result = service.rewrite_message

    if result[:success]
      render json: { text: result[:rewritten_text] }
    else
      render json: { error: result[:error] || "Failed to rewrite message" }, status: :unprocessable_entity
    end
  end

  def chat_summarize
    messages = params[:messages] || []
    if messages.empty?
      return render json: { error: "Messages array is required" }, status: :unprocessable_entity
    end

    service = AiMultimodalChatService.new(messages: messages)
    result = service.summarize_conversation

    if result[:success]
      render json: { summary: result[:summary], sentiment: result[:sentiment] }
    else
      render json: { error: result[:error] || "Summarization failed" }, status: :unprocessable_entity
    end
  end

  def search
    query = params[:query]

    if query.blank?
      return render json: { error: "Query is required" }, status: :unprocessable_entity
    end

    service = AiSearchService.new(query, current_user)
    result = service.generate

    if result[:success]
      render json: { answer: result[:answer], results: result[:results] }
    else
      render json: { error: result[:error] || "Failed to perform AI search" }, status: :unprocessable_entity
    end
  end

  def translate_text
    text = params[:text]
    target_language = params[:target_language]

    if text.blank? || target_language.blank?
      return render json: { error: "Text and target_language are required" }, status: :unprocessable_entity
    end

    service = AiTranslationService.new(text, target_language)
    result = service.translate

    if result[:success]
      render json: { translated_text: result[:translated_text] }
    else
      render json: { error: result[:error] || "Translation failed" }, status: :unprocessable_entity
    end
  end

  def copilot
    prompt = params[:prompt]

    if prompt.blank?
      return render json: { error: "Prompt is required" }, status: :unprocessable_entity
    end

    service = AiCopilotService.new(prompt, current_user)
    result = service.execute

    if result[:success]
      render json: { answer: result[:answer], action: result[:action] }
    else
      render json: { error: result[:error] || "Copilot execution failed" }, status: :unprocessable_entity
    end
  end

  def estimate_price
    service = AiMarketplaceValuationService.new(params)
    result = service.estimate_price

    if result[:success]
      render json: result
    else
      render json: { error: result[:error] }, status: :unprocessable_entity
    end
  end

  def negotiate_offer
    listing = MarketplaceListing.find_by(id: params[:listing_id])
    if listing.nil?
      return render json: { error: "Listing not found" }, status: :not_found
    end

    offer_price = params[:offer_price]
    result = AiMarketplaceValuationService.negotiate_offer(listing, offer_price)
    render json: result
  end

  def generate_reel
    text = params[:text]
    title = params[:title]

    if text.blank?
      return render json: { error: "Text content is required" }, status: :unprocessable_entity
    end

    service = AiReelStudioService.new(text, title)
    result = service.generate

    if result[:success]
      render json: result
    else
      render json: { error: result[:error] || "Failed to generate reel" }, status: :unprocessable_entity
    end
  end
end
