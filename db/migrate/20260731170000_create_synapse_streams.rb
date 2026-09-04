class CreateSynapseStreams < ActiveRecord::Migration[8.1]
  def change
    create_table :synapse_streams do |t|
      t.references :user, null: false, foreign_key: true
      t.string :primary_intent, default: "general", null: false # "storytelling", "commerce", "educational", "general"
      t.text :raw_input_text
      t.text :audio_transcription
      t.jsonb :synthesized_article_data, default: {}
      t.jsonb :synthesized_reel_data, default: {}
      t.jsonb :synthesized_post_data, default: {}
      t.jsonb :synthesized_marketplace_data, default: {}
      t.string :status, default: "draft", null: false # "draft", "synthesized", "published"
      t.jsonb :published_records, default: {} # Stores created record IDs { post_id: X, article_id: Y }

      t.timestamps
    end

    add_index :synapse_streams, [:user_id, :created_at]
    add_index :synapse_streams, :status
  end
end
