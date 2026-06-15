class AddNewFeaturesToApp < ActiveRecord::Migration[8.1]
  def change
    # ── Feature: Post Scheduling ──────────────────────────────────────────────
    add_column :posts, :scheduled_at,  :datetime
    add_column :posts, :published,     :boolean, null: false, default: true
    add_index  :posts, :scheduled_at
    add_index  :posts, :published

    # ── Feature: Link Previews on Posts ───────────────────────────────────────
    add_column :posts, :link_url,           :string
    add_column :posts, :link_title,         :string
    add_column :posts, :link_description,   :text
    add_column :posts, :link_image_url,     :string
    add_column :posts, :link_domain,        :string

    # ── Feature: Close Friends List ───────────────────────────────────────────
    create_table :close_friends do |t|
      t.references :user,        null: false, foreign_key: true
      t.references :close_friend, null: false, foreign_key: { to_table: :users }
      t.timestamps
    end
    add_index :close_friends, [:user_id, :close_friend_id], unique: true

    # ── Feature: Profile — Link in Bio, Birthday, Verification ───────────────
    add_column :users, :website_url,   :string
    add_column :users, :birthday,      :date
    add_column :users, :verified,      :boolean, null: false, default: false
    add_column :users, :location,      :string
    add_index  :users, :verified

    # ── Feature: Story Archive (auto-save expired stories) ────────────────────
    add_column :stories, :archived,    :boolean, null: false, default: false
    add_index  :stories, :archived

    # ── Feature: Dark Mode preference ─────────────────────────────────────────
    add_column :users, :dark_mode,     :boolean, null: false, default: false

    # ── Feature: Story Polls ───────────────────────────────────────────────────
    add_column :stories, :poll_question,  :string
    add_column :stories, :poll_option_a,  :string
    add_column :stories, :poll_option_b,  :string
    add_column :stories, :poll_votes_a,   :integer, null: false, default: 0
    add_column :stories, :poll_votes_b,   :integer, null: false, default: 0

    # ── Feature: Story Q&A ────────────────────────────────────────────────────
    add_column :stories, :qa_question,    :string

    # ── Feature: Location on Posts ────────────────────────────────────────────
    add_column :posts, :location_name,  :string
    add_column :posts, :latitude,       :decimal, precision: 10, scale: 6
    add_column :posts, :longitude,      :decimal, precision: 10, scale: 6

    # ── Feature: Story Q&A Replies ────────────────────────────────────────────
    create_table :story_qa_replies do |t|
      t.references :story,    null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true
      t.text       :answer,   null: false
      t.timestamps
    end

    # ── Feature: Story Poll Votes ─────────────────────────────────────────────
    create_table :story_poll_votes do |t|
      t.references :story,  null: false, foreign_key: true
      t.references :user,   null: false, foreign_key: true
      t.string     :option, null: false  # 'a' or 'b'
      t.timestamps
    end
    add_index :story_poll_votes, [:story_id, :user_id], unique: true

    # ── Feature: Mutual friends count (cached on friendship) ──────────────────
    # No schema change needed - computed on the fly

    # ── Feature: Birthday notification type (extend notifications) ────────────
    # No schema change needed - just a new notification_type string

    # ── Feature: Post Analytics ───────────────────────────────────────────────
    add_column :posts, :views_count, :integer, null: false, default: 0
    add_column :posts, :reach_count, :integer, null: false, default: 0

    # ── Feature: Memory/On This Day (no schema needed, query-based) ───────────

    # ── Feature: Fundraiser Posts ─────────────────────────────────────────────
    create_table :fundraisers do |t|
      t.references :post,      null: false, foreign_key: true
      t.string  :title,        null: false
      t.text    :description
      t.decimal :goal_amount,  precision: 10, scale: 2, null: false
      t.decimal :raised_amount, precision: 10, scale: 2, null: false, default: 0
      t.string  :currency,     null: false, default: 'USD'
      t.datetime :ends_at
      t.string  :status,       null: false, default: 'active'
      t.timestamps
    end

    # ── Feature: Marketplace Listings ─────────────────────────────────────────
    create_table :marketplace_listings do |t|
      t.references :user,        null: false, foreign_key: true
      t.string  :title,          null: false
      t.text    :description
      t.decimal :price,          precision: 10, scale: 2
      t.string  :category,       null: false, default: 'other'
      t.string  :condition,      null: false, default: 'used'
      t.string  :location_name
      t.string  :status,         null: false, default: 'active'
      t.integer :views_count,    null: false, default: 0
      t.boolean :price_negotiable, null: false, default: false
      t.timestamps
    end
    add_index :marketplace_listings, :status
    add_index :marketplace_listings, :category

    # ── Feature: Collaborative Posts ──────────────────────────────────────────
    create_table :post_collaborators do |t|
      t.references :post,  null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.string  :status,   null: false, default: 'pending'  # pending/accepted/rejected
      t.timestamps
    end
    add_index :post_collaborators, [:post_id, :user_id], unique: true

    # ── Feature: Event Reminders ──────────────────────────────────────────────
    add_column :events, :reminder_sent, :boolean, null: false, default: false
    add_column :events, :cover_image_url, :string

    # ── Feature: Group Events (link events to groups) ─────────────────────────
    add_column :events, :group_id, :bigint
    add_index  :events, :group_id
  end
end
