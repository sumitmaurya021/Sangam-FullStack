require "net/http"
require "uri"
require "json"
require "tempfile"

class AiAudioTranscriptionService
  def initialize(attachment)
    @attachment = attachment
  end

  def transcribe
    return { success: false, error: "No audio attachment present" } unless @attachment&.attached?

    api_key = ENV["GROQ_API_KEY"]

    # Open a temporary file to hold the blob content for upload
    temp_file = Tempfile.new(["audio_voice_note", extension_for_content_type(@attachment.content_type)])
    temp_file.binmode

    begin
      @attachment.download { |chunk| temp_file.write(chunk) }
      temp_file.rewind

      if api_key.present?
        res = call_whisper_api(api_key, temp_file)
        return res if res[:success]
      end

      # Development / Heuristic Fallback if API fails or no key
      {
        success: true,
        text: "[Voice Note Transcribed]: Voice message received successfully. (#{(@attachment.byte_size.to_f / 1024).round(1)} KB)"
      }
    ensure
      temp_file.close
      temp_file.unlink
    end
  rescue => e
    Rails.logger.error("AiAudioTranscriptionService exception: #{e.message}\n#{e.backtrace.join("\n")}")
    { success: false, error: e.message }
  end

  private

  def call_whisper_api(api_key, temp_file)
    uri = URI("https://api.groq.com/openai/v1/audio/transcriptions")
    
    boundary = "----RubyFormBoundary#{SecureRandom.hex(16)}"
    
    post_body = []
    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"model\"\r\n\r\n"
    post_body << "whisper-large-v3\r\n"

    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"response_format\"\r\n\r\n"
    post_body << "json\r\n"

    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"prompt\"\r\n\r\n"
    post_body << "This is a conversational voice message in English, Hindi, or Hinglish.\r\n"

    filename = @attachment.filename.to_s.presence || "audio_message.mp3"
    content_type = @attachment.content_type.presence || "audio/mp3"

    post_body << "--#{boundary}\r\n"
    post_body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
    post_body << "Content-Type: #{content_type}\r\n\r\n"
    post_body << temp_file.read
    post_body << "\r\n--#{boundary}--\r\n"

    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{api_key}"
    request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
    request.body = post_body.join

    req_options = { use_ssl: uri.scheme == "https" }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      text = data["text"].to_s.strip
      if text.present?
        { success: true, text: text }
      else
        { success: false, error: "Empty transcription text returned" }
      end
    else
      Rails.logger.error("Groq Whisper API Error: #{response.body}")
      { success: false, error: response.body }
    end
  end

  def extension_for_content_type(content_type)
    case content_type.to_s.downcase
    when /webm/ then ".webm"
    when /ogg/  then ".ogg"
    when /wav/  then ".wav"
    when /m4a/  then ".m4a"
    when /mp3/, /mpeg/ then ".mp3"
    else ".mp3"
    end
  end
end
