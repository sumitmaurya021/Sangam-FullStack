class CreateGroupChats < ActiveRecord::Migration[8.1]
  def change
    # ── group_chats ──────────────────────────────────────────────────────────
    create_table :group_chats do |t|
      t.string     :name,        null: false
      t.text       :description
      t.references :owner,       null: false, foreign_key: { to_table: :users }, index: true
      t.integer    :members_count, null: false, default: 0
      t.timestamps
    end

    add_index :group_chats, :name

    # ── group_chat_members ───────────────────────────────────────────────────
    create_table :group_chat_members do |t|
      t.references :group_chat, null: false, foreign_key: true, index: true
      t.references :user,       null: false, foreign_key: true, index: true
      t.string     :role,       null: false, default: 'member'   # member | admin
      t.timestamps
    end

    add_index :group_chat_members, [:group_chat_id, :user_id], unique: true
    add_index :group_chat_members, :role

    # ── group_chat_messages ──────────────────────────────────────────────────
    create_table :group_chat_messages do |t|
      t.references :group_chat,   null: false, foreign_key: true, index: true
      t.references :user,         null: false, foreign_key: true, index: true
      t.text       :body
      t.string     :message_type, null: false, default: 'text'
      t.boolean    :deleted,      null: false, default: false
      t.timestamps
    end

    add_index :group_chat_messages, :created_at
    add_index :group_chat_messages, :deleted
    add_index :group_chat_messages, :message_type

    # Active Storage attachment handled by polymorphic AS — no extra column needed
  end
end
