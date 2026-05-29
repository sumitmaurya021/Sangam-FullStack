class CreateConversations < ActiveRecord::Migration[8.1]
  def change
    create_table :conversations do |t|
      t.bigint :sender_id, null: false
      t.bigint :recipient_id, null: false
      t.datetime :last_message_at
      t.timestamps
    end

    add_index :conversations, :sender_id
    add_index :conversations, :recipient_id
    add_index :conversations, [:sender_id, :recipient_id], unique: true
    add_index :conversations, :last_message_at

    add_foreign_key :conversations, :users, column: :sender_id
    add_foreign_key :conversations, :users, column: :recipient_id
  end
end
