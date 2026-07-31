class CreateAiModerationLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :ai_moderation_logs do |t|
      t.references :user, foreign_key: true
      t.string :target_type
      t.bigint :target_id
      t.text :content_snippet
      t.float :toxicity_score, default: 0.0
      t.string :flagged_categories
      t.string :action_taken, default: "approved" # approved, blocked, flagged_for_review
      t.text :reason

      t.timestamps
    end

    add_index :ai_moderation_logs, [:target_type, :target_id]
    add_index :ai_moderation_logs, :action_taken
  end
end
