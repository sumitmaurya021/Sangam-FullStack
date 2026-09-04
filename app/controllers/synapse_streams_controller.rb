class SynapseStreamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_synapse_stream, only: [:show, :publish]

  def index
    @streams = current_user.synapse_streams.recent.limit(15)
    @active_stream = @streams.first || current_user.synapse_streams.build
  end

  def show
    @streams = current_user.synapse_streams.recent.limit(15)
    @active_stream = @stream
    render :index
  end


  def create
    raw_text = params[:raw_input_text]
    audio_transcription = params[:audio_transcription]
    primary_intent = params[:primary_intent] || "general"

    if raw_text.blank? && audio_transcription.blank?
      return redirect_to synapse_streams_path, alert: "Please provide a text prompt or voice recording."
    end

    @stream = current_user.synapse_streams.create!(
      raw_input_text: raw_text,
      audio_transcription: audio_transcription,
      primary_intent: primary_intent,
      status: "draft"
    )

    # Enqueue background job to prevent web server thread blocking
    SynthesizeSynapseStreamJob.perform_later(@stream.id)

    redirect_to synapse_stream_path(@stream), notice: "✨ Cross-Modal Stream synthesis queued in background!"
  end

  def publish
    unless @stream.synthesized?
      return redirect_to synapse_stream_path(@stream), alert: "Stream is not synthesized yet."
    end

    published_ids = {}

    # 1. Publish Social Post
    post_data = @stream.synthesized_post_data
    if post_data.present? && post_data["content"].present?
      hashtags = (post_data["hashtags"] || []).join(" ")
      full_content = "#{post_data['content']}\n\n#{hashtags}".strip
      post = current_user.posts.create!(content: full_content)
      published_ids["post_id"] = post.id
    end

    # 2. Publish Rich Article
    article_data = @stream.synthesized_article_data
    if article_data.present? && article_data["title"].present?
      article = current_user.articles.create!(
        title: article_data["title"],
        published: true
      )
      published_ids["article_id"] = article.id
    end

    # 3. Publish Reel Draft
    reel_data = @stream.synthesized_reel_data
    if reel_data.present? && reel_data["title"].present?
      reel = current_user.reels.create!(
        caption: "#{reel_data['title']} — #{reel_data['hooks']}".strip
      ) rescue nil
      published_ids["reel_id"] = reel.id if reel
    end

    # 4. Publish Marketplace Listing if commerce intent exists
    mkt_data = @stream.synthesized_marketplace_data
    if mkt_data.present? && mkt_data["title"].present? && (mkt_data["has_selling_intent"] == true || mkt_data["price"].to_f > 0)
      listing = current_user.marketplace_listings.create!(
        title: mkt_data["title"],
        price: mkt_data["price"] || 10.0,
        description: mkt_data["description"] || "Synthesized item",
        category: mkt_data["category"] || "General",
        status: "active"
      ) rescue nil
      published_ids["marketplace_id"] = listing.id if listing
    end

    @stream.update!(
      status: "published",
      published_records: published_ids
    )

    redirect_to synapse_stream_path(@stream), notice: "🚀 All synthesized content streams published live to Sangam!"
  end

  private

  def set_synapse_stream
    @stream = current_user.synapse_streams.find(params[:id])
  end
end
