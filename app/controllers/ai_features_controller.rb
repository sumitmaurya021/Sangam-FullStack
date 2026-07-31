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
    tone = params[:tone]

    if text.blank? || tone.blank?
      return render json: { error: "Text and tone are required" }, status: :unprocessable_entity
    end

    service = AiMessageRewriterService.new(text, tone)
    result = service.generate

    if result[:success]
      render json: { text: result[:text] }
    else
      render json: { error: result[:error] || "Failed to rewrite message" }, status: :unprocessable_entity
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
end
