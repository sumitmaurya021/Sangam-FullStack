class AddTranscriptionToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :transcription, :text
    add_column :messages, :transcription_status, :string

    add_column :group_chat_messages, :transcription, :text
    add_column :group_chat_messages, :transcription_status, :string
  end
end
