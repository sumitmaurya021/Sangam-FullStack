class CreateNotifications < ActiveRecord::Migration[8.1]
  def change
    create_table :notifications do |t|
      t.references :recipient, null: false, foreign_key: { to_table: :users }, index: true
      t.references :actor, null: false, foreign_key: { to_table: :users }, index: true
      t.references :notifiable, polymorphic: true, null: true, index: true
      t.string :notification_type, null: false
      t.text :message
      t.datetime :read_at
      t.timestamps
    end

    add_index :notifications, [:recipient_id, :read_at]
    add_index :notifications, [:recipient_id, :created_at]
    add_index :notifications, :notification_type
  end
end
