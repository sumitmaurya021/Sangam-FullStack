require 'open-uri'
require 'nokogiri'

# Fetches OG/meta link preview for a URL — used in post creation
# GET /link_preview?url=https://example.com
class LinkPreviewsController < ApplicationController
  before_action :authenticate_user!

  def show
    url = params[:url].to_s.strip
    return render json: { error: 'URL required' }, status: :bad_request if url.blank?

    # Only allow http/https
    unless url =~ /\Ahttps?:\/\//i
      return render json: { error: 'Invalid URL' }, status: :unprocessable_entity
    end

    preview = fetch_preview(url)
    render json: preview
  rescue => e
    Rails.logger.error "LinkPreview error: #{e.message}"
    render json: { error: 'Could not fetch preview' }, status: :service_unavailable
  end

  private

  def fetch_preview(url)
    uri    = URI.parse(url)
    domain = uri.host.to_s.sub(/\Awww\./, '')

    html = nil
    # Timeout guard
    Timeout.timeout(8) do
      html = URI.open(url,
        'User-Agent' => 'Mozilla/5.0 (compatible; SangamBot/1.0)',
        read_timeout: 6,
        open_timeout: 4
      ).read
    end

    doc = Nokogiri::HTML(html)

    title       = og_or_meta(doc, 'title')       || doc.at('title')&.text&.strip
    description = og_or_meta(doc, 'description')
    image       = og_or_meta(doc, 'image')

    # Resolve relative image URL
    if image.present? && !image.start_with?('http')
      image = "#{uri.scheme}://#{uri.host}#{image}"
    end

    {
      url:         url,
      title:       title&.truncate(120),
      description: description&.truncate(300),
      image:       image,
      domain:      domain
    }
  end

  def og_or_meta(doc, property)
    # OpenGraph
    node = doc.at("meta[property='og:#{property}']")
    return node['content'].strip if node && node['content'].present?

    # Twitter card
    node = doc.at("meta[name='twitter:#{property}']")
    return node['content'].strip if node && node['content'].present?

    # Standard meta
    node = doc.at("meta[name='#{property}']")
    return node['content'].strip if node && node['content'].present?

    nil
  end
end
