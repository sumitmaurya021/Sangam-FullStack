class MusicSearchController < ApplicationController
  require 'net/http'
  require 'json'
  require 'uri'

  before_action :authenticate_user!

  # GET /music/search?q=arijit+singh
  # iTunes Search API — free, no key, worldwide real music with 30s previews
  def search
    query = params[:q].to_s.strip
    return render json: { tracks: [] } if query.length < 2

    tracks = fetch_itunes_tracks(query)
    render json: { tracks: tracks }

  rescue => e
    Rails.logger.error "Music search error: #{e.class} #{e.message}"
    render json: { tracks: [], error: e.message }, status: :service_unavailable
  end

  private

  def fetch_itunes_tracks(query)
    encoded = URI.encode_www_form_component(query)
    url = "https://itunes.apple.com/search?term=#{encoded}&media=music&entity=song&limit=20&explicit=No"

    uri = URI(url)
    response_body = nil

    # Use a thread to avoid rack-timeout killing the request
    thread = Thread.new do
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl      = true
      http.open_timeout = 8
      http.read_timeout = 12

      req = Net::HTTP::Get.new(uri.request_uri)
      req['User-Agent'] = 'Mozilla/5.0 (compatible; SangamApp/1.0)'
      req['Accept']     = 'application/json'

      res = http.request(req)
      response_body = res.body if res.is_a?(Net::HTTPSuccess)
    end

    thread.join(14) # wait max 14 seconds

    return [] unless response_body

    data = JSON.parse(response_body)
    (data['results'] || []).map do |t|
      {
        id:       t['trackId'],
        title:    t['trackName'],
        artist:   t['artistName'],
        album:    t['collectionName'],
        cover:    t['artworkUrl100'] || t['artworkUrl60'],
        preview:  t['previewUrl'],
        duration: t['trackTimeMillis'] ? (t['trackTimeMillis'] / 1000).to_i : nil,
        genre:    t['primaryGenreName']
      }
    end
  end
end
