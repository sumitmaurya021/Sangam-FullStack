class CreateDigitalTwinsAndTwinLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :digital_twins do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :enabled, default: false, null: false
      t.string :mode, default: "away_only", null: false # "always_on", "away_only", "scheduled"
      t.string :persona_name, default: "Digital Twin"
      t.string :tone, default: "friendly_professional"
      t.text :custom_instructions
      t.boolean :auto_reply_dms, default: true, null: false
      t.boolean :auto_reply_marketplace, default: true, null: false
      t.boolean :auto_reply_group_chats, default: false, null: false
      t.decimal :min_marketplace_offer, precision: 10, scale: 2, default: 0.0
      t.jsonb :guardrails, default: {
        prohibit_financial_info: true,
        prohibit_personal_phone: true,
        max_daily_replies: 50,
        flag_topics: ["password", "bank", "address"]
      }

      t.timestamps
    end

    create_table :digital_twin_logs do |t|
      t.references :digital_twin, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :trigger_source, null: false # "direct_message", "marketplace", "group_chat"
      t.string :sender_name
      t.text :input_text
      t.text :output_text
      t.string :status, default: "executed", null: false # "executed", "blocked_by_guardrail", "error"
      t.string :reason

      t.timestamps
    end

    add_index :digital_twin_logs, [:user_id, :created_at]
    add_index :digital_twin_logs, :status
  end
end
