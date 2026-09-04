# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_09_04_160000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "ai_moderation_logs", force: :cascade do |t|
    t.string "action_taken", default: "approved"
    t.text "content_snippet"
    t.datetime "created_at", null: false
    t.string "flagged_categories"
    t.text "reason"
    t.bigint "target_id"
    t.string "target_type"
    t.float "toxicity_score", default: 0.0
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["action_taken"], name: "index_ai_moderation_logs_on_action_taken"
    t.index ["target_type", "target_id"], name: "index_ai_moderation_logs_on_target_type_and_target_id"
    t.index ["user_id"], name: "index_ai_moderation_logs_on_user_id"
  end

  create_table "articles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "embedding_data"
    t.boolean "published", default: true, null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["user_id"], name: "index_articles_on_user_id"
  end

  create_table "bookmark_collections", force: :cascade do |t|
    t.integer "cover_item_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_default", default: false, null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_bookmark_collections_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_bookmark_collections_on_user_id"
  end

  create_table "bookmarks", force: :cascade do |t|
    t.bigint "bookmark_collection_id"
    t.bigint "bookmarkable_id"
    t.string "bookmarkable_type"
    t.datetime "created_at", null: false
    t.bigint "post_id"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["bookmark_collection_id"], name: "index_bookmarks_on_bookmark_collection_id"
    t.index ["bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_on_bookmarkable"
    t.index ["post_id"], name: "index_bookmarks_on_post_id"
    t.index ["user_id", "bookmarkable_type", "bookmarkable_id"], name: "index_bookmarks_unique_per_user", unique: true
    t.index ["user_id", "post_id"], name: "index_bookmarks_on_user_id_and_post_id", unique: true
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "category_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_category_tags_on_slug", unique: true
  end

  create_table "close_friends", force: :cascade do |t|
    t.bigint "close_friend_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["close_friend_id"], name: "index_close_friends_on_close_friend_id"
    t.index ["user_id", "close_friend_id"], name: "index_close_friends_on_user_id_and_close_friend_id", unique: true
    t.index ["user_id"], name: "index_close_friends_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "content"
    t.datetime "created_at", null: false
    t.string "flag_reason"
    t.boolean "flagged", default: false, null: false
    t.bigint "parent_id"
    t.bigint "post_id", null: false
    t.bigint "replied_to_user_id"
    t.integer "replies_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["flagged"], name: "index_comments_on_flagged"
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["replied_to_user_id"], name: "index_comments_on_replied_to_user_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "last_message_at"
    t.bigint "recipient_id", null: false
    t.bigint "sender_id", null: false
    t.datetime "updated_at", null: false
    t.index ["last_message_at"], name: "index_conversations_on_last_message_at"
    t.index ["recipient_id"], name: "index_conversations_on_recipient_id"
    t.index ["sender_id", "recipient_id"], name: "index_conversations_on_sender_id_and_recipient_id", unique: true
    t.index ["sender_id"], name: "index_conversations_on_sender_id"
  end

  create_table "digital_twin_logs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "digital_twin_id", null: false
    t.text "input_text"
    t.text "output_text"
    t.string "reason"
    t.string "sender_name"
    t.string "status", default: "executed", null: false
    t.string "trigger_source", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["digital_twin_id"], name: "index_digital_twin_logs_on_digital_twin_id"
    t.index ["status"], name: "index_digital_twin_logs_on_status"
    t.index ["user_id", "created_at"], name: "index_digital_twin_logs_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_digital_twin_logs_on_user_id"
  end

  create_table "digital_twins", force: :cascade do |t|
    t.boolean "auto_reply_dms", default: true, null: false
    t.boolean "auto_reply_group_chats", default: false, null: false
    t.boolean "auto_reply_marketplace", default: true, null: false
    t.datetime "created_at", null: false
    t.text "custom_instructions"
    t.boolean "enabled", default: false, null: false
    t.jsonb "guardrails", default: {"flag_topics"=>["password", "bank", "address"], "max_daily_replies"=>50, "prohibit_financial_info"=>true, "prohibit_personal_phone"=>true}
    t.decimal "min_marketplace_offer", precision: 10, scale: 2, default: "0.0"
    t.string "mode", default: "away_only", null: false
    t.string "persona_name", default: "Digital Twin"
    t.string "tone", default: "friendly_professional"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_digital_twins_on_user_id", unique: true
  end

  create_table "event_responses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.string "response", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["event_id", "user_id"], name: "index_event_responses_on_event_id_and_user_id", unique: true
    t.index ["event_id"], name: "index_event_responses_on_event_id"
    t.index ["user_id"], name: "index_event_responses_on_user_id"
  end

  create_table "events", force: :cascade do |t|
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "ends_at"
    t.integer "going_count", default: 0, null: false
    t.bigint "group_id"
    t.integer "interested_count", default: 0, null: false
    t.string "location"
    t.bigint "organizer_id", null: false
    t.string "privacy", default: "public", null: false
    t.boolean "reminder_sent", default: false, null: false
    t.datetime "starts_at", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_events_on_group_id"
    t.index ["organizer_id"], name: "index_events_on_organizer_id"
    t.index ["starts_at"], name: "index_events_on_starts_at"
  end

  create_table "follows", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "followee_id", null: false
    t.bigint "follower_id", null: false
    t.datetime "updated_at", null: false
    t.index ["followee_id"], name: "index_follows_on_followee_id"
    t.index ["follower_id", "followee_id"], name: "index_follows_on_follower_id_and_followee_id", unique: true
    t.index ["follower_id"], name: "index_follows_on_follower_id"
  end

  create_table "friendships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "friend_id", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["friend_id"], name: "index_friendships_on_friend_id"
    t.index ["status"], name: "index_friendships_on_status"
    t.index ["user_id", "friend_id"], name: "index_friendships_on_user_id_and_friend_id", unique: true
    t.index ["user_id"], name: "index_friendships_on_user_id"
  end

  create_table "fundraisers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", default: "USD", null: false
    t.text "description"
    t.datetime "ends_at"
    t.decimal "goal_amount", precision: 10, scale: 2, null: false
    t.bigint "post_id", null: false
    t.decimal "raised_amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "active", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_fundraisers_on_post_id"
  end

  create_table "group_chat_members", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_chat_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_chat_id", "user_id"], name: "index_group_chat_members_on_group_chat_id_and_user_id", unique: true
    t.index ["group_chat_id"], name: "index_group_chat_members_on_group_chat_id"
    t.index ["role"], name: "index_group_chat_members_on_role"
    t.index ["user_id"], name: "index_group_chat_members_on_user_id"
  end

  create_table "group_chat_messages", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.bigint "group_chat_id", null: false
    t.string "message_type", default: "text", null: false
    t.text "transcription"
    t.string "transcription_status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_group_chat_messages_on_created_at"
    t.index ["deleted"], name: "index_group_chat_messages_on_deleted"
    t.index ["group_chat_id"], name: "index_group_chat_messages_on_group_chat_id"
    t.index ["message_type"], name: "index_group_chat_messages_on_message_type"
    t.index ["user_id"], name: "index_group_chat_messages_on_user_id"
  end

  create_table "group_chats", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "members_count", default: 0, null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_group_chats_on_name"
    t.index ["owner_id"], name: "index_group_chats_on_owner_id"
  end

  create_table "group_memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "group_id", null: false
    t.string "role", default: "member", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["group_id", "user_id"], name: "index_group_memberships_on_group_id_and_user_id", unique: true
    t.index ["group_id"], name: "index_group_memberships_on_group_id"
    t.index ["user_id"], name: "index_group_memberships_on_user_id"
  end

  create_table "groups", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "members_count", default: 0, null: false
    t.string "name", null: false
    t.bigint "owner_id", null: false
    t.integer "posts_count", default: 0, null: false
    t.string "privacy", default: "public", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_groups_on_name"
    t.index ["owner_id"], name: "index_groups_on_owner_id"
  end

  create_table "hashtags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "posts_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_hashtags_on_name", unique: true
    t.index ["posts_count"], name: "index_hashtags_on_posts_count"
  end

  create_table "highlight_stories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "position", default: 0, null: false
    t.bigint "profile_highlight_id", null: false
    t.bigint "story_id", null: false
    t.datetime "updated_at", null: false
    t.index ["profile_highlight_id", "story_id"], name: "index_highlight_stories_on_profile_highlight_id_and_story_id", unique: true
    t.index ["profile_highlight_id"], name: "index_highlight_stories_on_profile_highlight_id"
    t.index ["story_id"], name: "index_highlight_stories_on_story_id"
  end

  create_table "likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.string "reaction_type", default: "like", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_likes_on_post_id"
    t.index ["reaction_type"], name: "index_likes_on_reaction_type"
    t.index ["user_id"], name: "index_likes_on_user_id"
  end

  create_table "marketplace_listings", force: :cascade do |t|
    t.string "category", default: "other", null: false
    t.string "condition", default: "used", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.text "embedding_data"
    t.string "location_name"
    t.decimal "price", precision: 10, scale: 2
    t.boolean "price_negotiable", default: false, null: false
    t.string "status", default: "active", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["category"], name: "index_marketplace_listings_on_category"
    t.index ["status"], name: "index_marketplace_listings_on_status"
    t.index ["user_id"], name: "index_marketplace_listings_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.boolean "deleted", default: false, null: false
    t.string "message_type", default: "text", null: false
    t.datetime "read_at"
    t.text "transcription"
    t.string "transcription_status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id", "created_at"], name: "index_messages_on_conversation_id_and_created_at"
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["created_at"], name: "index_messages_on_created_at"
    t.index ["message_type"], name: "index_messages_on_message_type"
    t.index ["read_at"], name: "index_messages_on_read_at"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.bigint "actor_id", null: false
    t.datetime "created_at", null: false
    t.text "message"
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.string "notification_type", null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["notification_type"], name: "index_notifications_on_notification_type"
    t.index ["notification_type"], name: "index_notifications_on_type_extended"
    t.index ["recipient_id", "created_at"], name: "index_notifications_on_recipient_id_and_created_at"
    t.index ["recipient_id", "read_at"], name: "index_notifications_on_recipient_id_and_read_at"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "poll_options", force: :cascade do |t|
    t.string "body", null: false
    t.datetime "created_at", null: false
    t.bigint "poll_id", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.integer "votes_count", default: 0, null: false
    t.index ["poll_id", "position"], name: "index_poll_options_on_poll_id_and_position"
    t.index ["poll_id"], name: "index_poll_options_on_poll_id"
  end

  create_table "poll_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "poll_id", null: false
    t.bigint "poll_option_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["poll_id", "user_id"], name: "index_poll_votes_on_poll_id_and_user_id", unique: true
    t.index ["poll_id"], name: "index_poll_votes_on_poll_id"
    t.index ["poll_option_id"], name: "index_poll_votes_on_poll_option_id"
    t.index ["user_id"], name: "index_poll_votes_on_user_id"
  end

  create_table "polls", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.boolean "expired", default: false, null: false
    t.bigint "post_id", null: false
    t.string "question", null: false
    t.datetime "updated_at", null: false
    t.index ["ends_at"], name: "index_polls_on_ends_at"
    t.index ["expired"], name: "index_polls_on_expired"
    t.index ["post_id"], name: "index_polls_on_post_id"
  end

  create_table "post_category_tags", force: :cascade do |t|
    t.bigint "category_tag_id", null: false
    t.float "confidence_score"
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["category_tag_id"], name: "index_post_category_tags_on_category_tag_id"
    t.index ["post_id"], name: "index_post_category_tags_on_post_id"
  end

  create_table "post_collaborators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id", "user_id"], name: "index_post_collaborators_on_post_id_and_user_id", unique: true
    t.index ["post_id"], name: "index_post_collaborators_on_post_id"
    t.index ["user_id"], name: "index_post_collaborators_on_user_id"
  end

  create_table "post_hashtags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "hashtag_id", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.index ["hashtag_id"], name: "index_post_hashtags_on_hashtag_id"
    t.index ["post_id", "hashtag_id"], name: "index_post_hashtags_on_post_id_and_hashtag_id", unique: true
    t.index ["post_id"], name: "index_post_hashtags_on_post_id"
  end

  create_table "post_mentions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "mentionable_id"
    t.string "mentionable_type"
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["mentionable_type", "mentionable_id"], name: "index_post_mentions_on_mentionable_type_and_mentionable_id"
    t.index ["post_id", "user_id"], name: "index_post_mentions_on_post_id_and_user_id", unique: true
    t.index ["post_id"], name: "index_post_mentions_on_post_id"
    t.index ["user_id"], name: "index_post_mentions_on_user_id"
  end

  create_table "post_mutations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.string "prompt_used"
    t.string "reaction_type"
    t.integer "status"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_post_mutations_on_post_id"
    t.index ["user_id"], name: "index_post_mutations_on_user_id"
  end

  create_table "post_universe_transformations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.integer "status"
    t.text "transformed_caption"
    t.bigint "universe_theme_id", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id"], name: "index_post_universe_transformations_on_post_id"
    t.index ["universe_theme_id"], name: "index_post_universe_transformations_on_universe_theme_id"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "comments_count", default: 0
    t.text "content"
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.text "embedding_data"
    t.string "flag_reason"
    t.boolean "flagged", default: false, null: false
    t.bigint "group_id"
    t.string "image"
    t.decimal "latitude", precision: 10, scale: 6
    t.integer "likes_count", default: 0
    t.text "link_description"
    t.string "link_domain"
    t.string "link_image_url"
    t.string "link_title"
    t.string "link_url"
    t.string "location_name"
    t.decimal "longitude", precision: 10, scale: 6
    t.string "music_artist"
    t.string "music_preview_url"
    t.string "music_title"
    t.boolean "published", default: true, null: false
    t.integer "reach_count", default: 0, null: false
    t.datetime "scheduled_at"
    t.integer "shares_count", default: 0
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.string "visibility", default: "public", null: false
    t.index ["created_at"], name: "index_posts_on_created_at"
    t.index ["flagged"], name: "index_posts_on_flagged"
    t.index ["group_id"], name: "index_posts_on_group_id"
    t.index ["published"], name: "index_posts_on_published"
    t.index ["scheduled_at"], name: "index_posts_on_scheduled_at"
    t.index ["user_id", "created_at"], name: "index_posts_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_posts_on_user_id"
    t.index ["visibility", "created_at"], name: "index_posts_on_visibility_and_created_at", order: { created_at: :desc }
    t.index ["visibility"], name: "index_posts_on_visibility"
  end

  create_table "profile_highlights", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji", default: "⭐"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "name"], name: "index_profile_highlights_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_profile_highlights_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key", null: false
    t.datetime "created_at", null: false
    t.text "endpoint", null: false
    t.string "p256dh_key", null: false
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint"
    t.index ["user_id", "endpoint"], name: "index_push_subscriptions_on_user_id_and_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "reel_comments", force: :cascade do |t|
    t.text "content", null: false
    t.datetime "created_at", null: false
    t.bigint "parent_id"
    t.bigint "reel_id", null: false
    t.integer "replies_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["parent_id"], name: "index_reel_comments_on_parent_id"
    t.index ["reel_id"], name: "index_reel_comments_on_reel_id"
    t.index ["user_id"], name: "index_reel_comments_on_user_id"
  end

  create_table "reel_likes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "reaction_type", default: "like", null: false
    t.bigint "reel_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["reaction_type"], name: "index_reel_likes_on_reaction_type"
    t.index ["reel_id", "user_id"], name: "index_reel_likes_on_reel_id_and_user_id", unique: true
    t.index ["reel_id"], name: "index_reel_likes_on_reel_id"
    t.index ["user_id"], name: "index_reel_likes_on_user_id"
  end

  create_table "reels", force: :cascade do |t|
    t.text "caption"
    t.integer "comments_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "duration"
    t.text "hashtags"
    t.integer "likes_count", default: 0, null: false
    t.string "music"
    t.string "music_artist"
    t.string "music_preview_url"
    t.string "music_title"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["created_at"], name: "index_reels_on_created_at"
    t.index ["user_id"], name: "index_reels_on_user_id"
  end

  create_table "shares", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_shares_on_post_id"
    t.index ["user_id"], name: "index_shares_on_user_id"
  end

  create_table "solid_cable_messages", force: :cascade do |t|
    t.binary "channel", null: false
    t.bigint "channel_hash", null: false
    t.datetime "created_at", null: false
    t.binary "payload", null: false
    t.index ["channel"], name: "index_solid_cable_messages_on_channel"
    t.index ["channel_hash"], name: "index_solid_cable_messages_on_channel_hash"
    t.index ["created_at"], name: "index_solid_cable_messages_on_created_at"
  end

  create_table "solid_cache_entries", force: :cascade do |t|
    t.integer "byte_size", null: false
    t.datetime "created_at", null: false
    t.binary "key", null: false
    t.bigint "key_hash", null: false
    t.binary "value", null: false
    t.index ["byte_size"], name: "index_solid_cache_entries_on_byte_size"
    t.index ["created_at"], name: "index_solid_cache_entries_on_created_at"
    t.index ["key_hash"], name: "index_solid_cache_entries_on_key_hash", unique: true
  end

  create_table "solid_queue_blocked_executions", force: :cascade do |t|
    t.string "concurrency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["concurrency_key", "priority", "job_id"], name: "idx_on_concurrency_key_priority_job_id_d4bdd8da1e"
    t.index ["expires_at", "concurrency_key"], name: "idx_on_expires_at_concurrency_key_c20fd0827b"
    t.index ["job_id"], name: "index_solid_queue_blocked_executions_on_job_id", unique: true
  end

  create_table "solid_queue_claimed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.bigint "process_id"
    t.index ["job_id"], name: "index_solid_queue_claimed_executions_on_job_id", unique: true
    t.index ["process_id", "job_id"], name: "index_solid_queue_claimed_executions_on_process_id_and_job_id"
  end

  create_table "solid_queue_failed_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "error"
    t.bigint "job_id", null: false
    t.index ["job_id"], name: "index_solid_queue_failed_executions_on_job_id", unique: true
  end

  create_table "solid_queue_jobs", force: :cascade do |t|
    t.string "active_job_id"
    t.text "arguments"
    t.string "class_name", null: false
    t.string "concurrency_key"
    t.datetime "created_at", null: false
    t.datetime "finished_at"
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at"
    t.datetime "updated_at", null: false
    t.index ["active_job_id"], name: "index_solid_queue_jobs_on_active_job_id"
    t.index ["class_name"], name: "index_solid_queue_jobs_on_class_name"
    t.index ["finished_at"], name: "index_solid_queue_jobs_on_finished_at"
    t.index ["queue_name", "finished_at"], name: "index_solid_queue_jobs_on_queue_name_and_finished_at"
    t.index ["scheduled_at", "finished_at"], name: "index_solid_queue_jobs_on_scheduled_at_and_finished_at"
  end

  create_table "solid_queue_pauses", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "queue_name", null: false
    t.index ["queue_name"], name: "index_solid_queue_pauses_on_queue_name", unique: true
  end

  create_table "solid_queue_processes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "hostname"
    t.string "kind", null: false
    t.datetime "last_heartbeat_at", null: false
    t.text "metadata"
    t.string "name", null: false
    t.integer "pid", null: false
    t.bigint "supervisor_id"
    t.index ["last_heartbeat_at"], name: "index_solid_queue_processes_on_last_heartbeat_at"
    t.index ["name", "supervisor_id"], name: "index_solid_queue_processes_on_name_and_supervisor_id", unique: true
    t.index ["supervisor_id"], name: "index_solid_queue_processes_on_supervisor_id"
  end

  create_table "solid_queue_ready_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.index ["job_id"], name: "index_solid_queue_ready_executions_on_job_id", unique: true
    t.index ["priority", "job_id"], name: "index_solid_queue_ready_executions_on_priority_and_job_id"
    t.index ["queue_name", "priority", "job_id"], name: "idx_on_queue_name_priority_job_id_b116c992cd"
  end

  create_table "solid_queue_recurring_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.datetime "run_at", null: false
    t.string "task_key", null: false
    t.index ["job_id"], name: "index_solid_queue_recurring_executions_on_job_id", unique: true
    t.index ["task_key", "run_at"], name: "index_solid_queue_recurring_executions_on_task_key_and_run_at", unique: true
  end

  create_table "solid_queue_recurring_tasks", force: :cascade do |t|
    t.text "arguments"
    t.string "class_name"
    t.string "command", limit: 2048
    t.datetime "created_at", null: false
    t.string "key", null: false
    t.datetime "last_run_at"
    t.integer "priority", default: 0
    t.string "queue_name"
    t.string "schedule", null: false
    t.boolean "static", default: true, null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_solid_queue_recurring_tasks_on_key", unique: true
    t.index ["static"], name: "index_solid_queue_recurring_tasks_on_static"
  end

  create_table "solid_queue_scheduled_executions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "job_id", null: false
    t.integer "priority", default: 0, null: false
    t.string "queue_name", null: false
    t.datetime "scheduled_at", null: false
    t.index ["job_id"], name: "index_solid_queue_scheduled_executions_on_job_id", unique: true
    t.index ["scheduled_at", "priority", "job_id"], name: "idx_on_scheduled_at_priority_job_id_cf978ceebd"
  end

  create_table "solid_queue_semaphores", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.string "key", null: false
    t.datetime "updated_at", null: false
    t.integer "value", default: 1, null: false
    t.index ["expires_at"], name: "index_solid_queue_semaphores_on_expires_at"
    t.index ["key", "value"], name: "index_solid_queue_semaphores_on_key_and_value"
    t.index ["key"], name: "index_solid_queue_semaphores_on_key", unique: true
  end

  create_table "stories", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.string "background_color", default: "#1a1a2e"
    t.text "caption"
    t.datetime "created_at", null: false
    t.datetime "expires_at", null: false
    t.boolean "is_shared_post", default: false, null: false
    t.string "poll_option_a"
    t.string "poll_option_b"
    t.string "poll_question"
    t.integer "poll_votes_a", default: 0, null: false
    t.integer "poll_votes_b", default: 0, null: false
    t.string "qa_question"
    t.bigint "shared_post_id"
    t.string "story_type", default: "image", null: false
    t.string "text_color", default: "#ffffff"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.integer "views_count", default: 0, null: false
    t.index ["archived"], name: "index_stories_on_archived"
    t.index ["expires_at"], name: "index_stories_on_expires_at"
    t.index ["is_shared_post"], name: "index_stories_on_is_shared_post"
    t.index ["shared_post_id"], name: "index_stories_on_shared_post_id"
    t.index ["user_id", "created_at"], name: "index_stories_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_stories_on_user_id"
  end

  create_table "story_poll_votes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "option", null: false
    t.bigint "story_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["story_id", "user_id"], name: "index_story_poll_votes_on_story_id_and_user_id", unique: true
    t.index ["story_id"], name: "index_story_poll_votes_on_story_id"
    t.index ["user_id"], name: "index_story_poll_votes_on_user_id"
  end

  create_table "story_qa_replies", force: :cascade do |t|
    t.text "answer", null: false
    t.datetime "created_at", null: false
    t.bigint "story_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["story_id"], name: "index_story_qa_replies_on_story_id"
    t.index ["user_id"], name: "index_story_qa_replies_on_user_id"
  end

  create_table "story_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "story_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["story_id", "user_id"], name: "index_story_views_on_story_id_and_user_id", unique: true
    t.index ["story_id"], name: "index_story_views_on_story_id"
    t.index ["user_id"], name: "index_story_views_on_user_id"
  end

  create_table "synapse_streams", force: :cascade do |t|
    t.text "audio_transcription"
    t.datetime "created_at", null: false
    t.string "primary_intent", default: "general", null: false
    t.jsonb "published_records", default: {}
    t.text "raw_input_text"
    t.string "status", default: "draft", null: false
    t.jsonb "synthesized_article_data", default: {}
    t.jsonb "synthesized_marketplace_data", default: {}
    t.jsonb "synthesized_post_data", default: {}
    t.jsonb "synthesized_reel_data", default: {}
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["status"], name: "index_synapse_streams_on_status"
    t.index ["user_id", "created_at"], name: "index_synapse_streams_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_synapse_streams_on_user_id"
  end

  create_table "universe_themes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.text "prompt_prefix"
    t.text "prompt_suffix"
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_universe_themes_on_slug"
  end

  create_table "user_interactions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "interaction_type"
    t.bigint "post_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["post_id"], name: "index_user_interactions_on_post_id"
    t.index ["user_id"], name: "index_user_interactions_on_user_id"
  end

  create_table "user_tag_affinities", force: :cascade do |t|
    t.bigint "category_tag_id", null: false
    t.datetime "created_at", null: false
    t.float "score"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["category_tag_id"], name: "index_user_tag_affinities_on_category_tag_id"
    t.index ["user_id", "category_tag_id"], name: "index_user_tag_affinities_on_user_id_and_category_tag_id"
    t.index ["user_id"], name: "index_user_tag_affinities_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar"
    t.text "bio"
    t.date "birthday"
    t.datetime "confirmation_sent_at"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.string "cover_photo"
    t.datetime "created_at", null: false
    t.boolean "dark_mode", default: false, null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.integer "failed_attempts", default: 0, null: false
    t.integer "followers_count", default: 0, null: false
    t.integer "following_count", default: 0, null: false
    t.boolean "is_ai", default: false
    t.datetime "last_seen_at"
    t.string "location"
    t.datetime "locked_at"
    t.string "name"
    t.boolean "online", default: false, null: false
    t.text "otp_backup_codes"
    t.boolean "otp_enabled", default: false, null: false
    t.string "otp_secret"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.boolean "super_admin", default: false, null: false
    t.string "uid"
    t.string "unconfirmed_email"
    t.string "unlock_token"
    t.integer "unread_notifications_count", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "verified", default: false, null: false
    t.string "website_url"
    t.index ["confirmation_token"], name: "index_users_on_confirmation_token", unique: true
    t.index ["created_at"], name: "index_users_on_created_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["last_seen_at"], name: "index_users_on_last_seen_at"
    t.index ["online"], name: "index_users_on_online"
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["super_admin"], name: "index_users_on_super_admin"
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
    t.index ["verified"], name: "index_users_on_verified"
  end

  create_table "ux_mutation_preferences", force: :cascade do |t|
    t.boolean "auto_adapt", default: true, null: false
    t.datetime "created_at", null: false
    t.jsonb "custom_rules", default: {}
    t.float "friction_score", default: 0.0, null: false
    t.string "layout_mode", default: "standard", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_ux_mutation_preferences_on_user_id", unique: true
  end

  create_table "ux_telemetry_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "duration_ms", default: 0
    t.string "event_type", null: false
    t.jsonb "metadata", default: {}
    t.string "page_route", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["created_at"], name: "index_ux_telemetry_events_on_created_at"
    t.index ["page_route", "event_type"], name: "index_ux_telemetry_events_on_page_route_and_event_type"
    t.index ["user_id"], name: "index_ux_telemetry_events_on_user_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "ai_moderation_logs", "users"
  add_foreign_key "articles", "users"
  add_foreign_key "bookmark_collections", "users"
  add_foreign_key "bookmarks", "bookmark_collections"
  add_foreign_key "bookmarks", "posts"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "close_friends", "users"
  add_foreign_key "close_friends", "users", column: "close_friend_id"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "comments", "users", column: "replied_to_user_id"
  add_foreign_key "conversations", "users", column: "recipient_id"
  add_foreign_key "conversations", "users", column: "sender_id"
  add_foreign_key "digital_twin_logs", "digital_twins"
  add_foreign_key "digital_twin_logs", "users"
  add_foreign_key "digital_twins", "users"
  add_foreign_key "event_responses", "events"
  add_foreign_key "event_responses", "users"
  add_foreign_key "events", "users", column: "organizer_id"
  add_foreign_key "follows", "users", column: "followee_id"
  add_foreign_key "follows", "users", column: "follower_id"
  add_foreign_key "friendships", "users"
  add_foreign_key "friendships", "users", column: "friend_id"
  add_foreign_key "fundraisers", "posts"
  add_foreign_key "group_chat_members", "group_chats"
  add_foreign_key "group_chat_members", "users"
  add_foreign_key "group_chat_messages", "group_chats"
  add_foreign_key "group_chat_messages", "users"
  add_foreign_key "group_chats", "users", column: "owner_id"
  add_foreign_key "group_memberships", "groups"
  add_foreign_key "group_memberships", "users"
  add_foreign_key "groups", "users", column: "owner_id"
  add_foreign_key "highlight_stories", "profile_highlights"
  add_foreign_key "highlight_stories", "stories"
  add_foreign_key "likes", "posts"
  add_foreign_key "likes", "users"
  add_foreign_key "marketplace_listings", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "poll_options", "polls"
  add_foreign_key "poll_votes", "poll_options"
  add_foreign_key "poll_votes", "polls"
  add_foreign_key "poll_votes", "users"
  add_foreign_key "polls", "posts"
  add_foreign_key "post_category_tags", "category_tags"
  add_foreign_key "post_category_tags", "posts"
  add_foreign_key "post_collaborators", "posts"
  add_foreign_key "post_collaborators", "users"
  add_foreign_key "post_hashtags", "hashtags"
  add_foreign_key "post_hashtags", "posts"
  add_foreign_key "post_mentions", "posts"
  add_foreign_key "post_mentions", "users"
  add_foreign_key "post_mutations", "posts"
  add_foreign_key "post_mutations", "users"
  add_foreign_key "post_universe_transformations", "posts"
  add_foreign_key "post_universe_transformations", "universe_themes"
  add_foreign_key "posts", "groups"
  add_foreign_key "posts", "users"
  add_foreign_key "profile_highlights", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "reel_comments", "reel_comments", column: "parent_id"
  add_foreign_key "reel_comments", "reels"
  add_foreign_key "reel_comments", "users"
  add_foreign_key "reel_likes", "reels"
  add_foreign_key "reel_likes", "users"
  add_foreign_key "reels", "users"
  add_foreign_key "shares", "posts"
  add_foreign_key "shares", "users"
  add_foreign_key "solid_queue_blocked_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_claimed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_failed_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_ready_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_recurring_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "solid_queue_scheduled_executions", "solid_queue_jobs", column: "job_id", on_delete: :cascade
  add_foreign_key "stories", "posts", column: "shared_post_id"
  add_foreign_key "stories", "users"
  add_foreign_key "story_poll_votes", "stories"
  add_foreign_key "story_poll_votes", "users"
  add_foreign_key "story_qa_replies", "stories"
  add_foreign_key "story_qa_replies", "users"
  add_foreign_key "story_views", "stories"
  add_foreign_key "story_views", "users"
  add_foreign_key "synapse_streams", "users"
  add_foreign_key "user_interactions", "posts"
  add_foreign_key "user_interactions", "users"
  add_foreign_key "user_tag_affinities", "category_tags"
  add_foreign_key "user_tag_affinities", "users"
  add_foreign_key "ux_mutation_preferences", "users"
  add_foreign_key "ux_telemetry_events", "users"
end
