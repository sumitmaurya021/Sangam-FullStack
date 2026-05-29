class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.bigint :conversation_id, null: false
      t.bigint :user_id, null: false
      t.text :body
      t.string :message_type, default: 'text', null: false  # text, image, file, gif, audio, video
      t.datetime :read_at
      t.boolean :deleted, default: false, null: false
      t.timestamps
    end

    add_index :messages, :conversation_id
    add_index :messages, :user_id
    add_index :messages, :created_at
    add_index :messages, :read_at
    add_index :messages, :message_type

    add_foreign_key :messages, :conversations
    add_foreign_key :messages, :users
  end
end
