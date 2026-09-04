class GenerateEmbeddingJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id)
    record = case record_type.to_s
             when "Post" then Post.find_by(id: record_id)
             when "Article" then Article.find_by(id: record_id)
             when "MarketplaceListing" then MarketplaceListing.find_by(id: record_id)
             end

    return unless record

    text_content = case record_type.to_s
                   when "Post" then record.content.to_s
                   when "Article" then "#{record.title} #{record.body.to_s}"
                   when "MarketplaceListing" then "#{record.title} #{record.description} #{record.category}"
                   end

    return if text_content.blank?

    vector = AiEmbeddingService.new(text_content).generate

    if record.respond_to?(:embedding=)
      record.update_columns(embedding: vector)
    elsif record.respond_to?(:embedding_data=)
      record.update_columns(embedding_data: vector.to_json)
    end
  rescue => e
    Rails.logger.error("GenerateEmbeddingJob failed for #{record_type} ##{record_id}: #{e.message}")
  end
end
