class RecreateSolidCableMessages < ActiveRecord::Migration[8.1]
  def up
    # Drop old table if exists (missing channel_hash column)
    drop_table :solid_cable_messages, if_exists: true

    # Recreate with correct schema for solid_cable 3.0.12
    create_table :solid_cable_messages do |t|
      t.binary  :channel,      limit: 1024,       null: false
      t.binary  :payload,      limit: 536_870_912, null: false
      t.integer :channel_hash, limit: 8,           null: false
      t.datetime :created_at,                      null: false
    end

    add_index :solid_cable_messages, :channel
    add_index :solid_cable_messages, :channel_hash
    add_index :solid_cable_messages, :created_at
  end

  def down
    drop_table :solid_cable_messages, if_exists: true
  end
end
