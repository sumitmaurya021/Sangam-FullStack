class CreateUxMutationPreferencesAndTelemetry < ActiveRecord::Migration[8.1]
  def change
    create_table :ux_mutation_preferences do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :layout_mode, default: "standard", null: false # "standard", "minimalist", "power_density", "voice_first"
      t.boolean :auto_adapt, default: true, null: false
      t.float :friction_score, default: 0.0, null: false
      t.jsonb :custom_rules, default: {}

      t.timestamps
    end

    create_table :ux_telemetry_events do |t|
      t.references :user, foreign_key: true, null: true
      t.string :page_route, null: false
      t.string :event_type, null: false # "form_abandonment", "field_hesitation", "rapid_backtrack"
      t.integer :duration_ms, default: 0
      t.jsonb :metadata, default: {}

      t.timestamps
    end

    add_index :ux_telemetry_events, [:page_route, :event_type]
    add_index :ux_telemetry_events, :created_at
  end
end
