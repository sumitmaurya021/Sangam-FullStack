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
end
