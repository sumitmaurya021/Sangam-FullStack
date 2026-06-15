class CreatePolls < ActiveRecord::Migration[8.1]
  def change
    # ── polls ────────────────────────────────────────────────────────────────
    create_table :polls do |t|
      t.references :post,       null: false, foreign_key: true, index: true
      t.string     :question,   null: false
      t.datetime   :ends_at                   # nil = never expires
      t.boolean    :expired,    null: false, default: false
      t.timestamps
    end

    add_index :polls, :ends_at
    add_index :polls, :expired

    # ── poll_options ─────────────────────────────────────────────────────────
    create_table :poll_options do |t|
      t.references :poll,       null: false, foreign_key: true, index: true
      t.string     :body,       null: false
      t.integer    :votes_count, null: false, default: 0
      t.integer    :position,   null: false, default: 0
      t.timestamps
    end

    add_index :poll_options, [:poll_id, :position]

    # ── poll_votes ────────────────────────────────────────────────────────────
    create_table :poll_votes do |t|
      t.references :poll_option, null: false, foreign_key: true, index: true
      t.references :user,        null: false, foreign_key: true, index: true
      t.references :poll,        null: false, foreign_key: true, index: true
      t.timestamps
    end

    # One vote per user per poll
    add_index :poll_votes, [:poll_id, :user_id], unique: true
  end
end
