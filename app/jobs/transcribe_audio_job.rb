class TranscribeAudioJob < ApplicationJob
  queue_as :default

  def perform(record_type, record_id)
    record = case record_type.to_s
             when "Message" then Message.find_by(id: record_id)
             when "GroupChatMessage" then GroupChatMessage.find_by(id: record_id)
             end

    return unless record && record.attachment.attached? && record.message_type == 'audio'

    record.update_columns(transcription_status: 'processing')

    service = AiAudioTranscriptionService.new(record.attachment)
    result = service.transcribe

    if result[:success]
      record.update_columns(
        transcription: result[:text],
        transcription_status: 'completed'
      )

      broadcast_transcription(record_type, record)
    else
      record.update_columns(transcription_status: 'failed')
      broadcast_transcription(record_type, record)
    end
  rescue => e
    Rails.logger.error("TranscribeAudioJob failed for #{record_type} ##{record_id}: #{e.message}")
  end

  private

  def broadcast_transcription(record_type, record)
    if record_type == "Message"
      ActionCable.server.broadcast(
        "conversation_#{record.conversation_id}",
        {
          type: 'transcription_updated',
          message_id: record.id,
          transcription: record.transcription,
          transcription_status: record.transcription_status
        }
      )
    elsif record_type == "GroupChatMessage"
      ActionCable.server.broadcast(
        "group_chat_#{record.group_chat_id}",
        {
          type: 'group_transcription_updated',
          message_id: record.id,
          transcription: record.transcription,
          transcription_status: record.transcription_status
        }
      )
    end
  end
end
