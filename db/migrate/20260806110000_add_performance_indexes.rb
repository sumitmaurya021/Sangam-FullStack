class AddPerformanceIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Optimize Suggested Users and Feed Queries
    add_index :users, :created_at, algorithm: :concurrently unless index_exists?(:users, :created_at)

    # Optimize Direct Messages lookup
    add_index :messages, [:conversation_id, :created_at], algorithm: :concurrently unless index_exists?(:messages, [:conversation_id, :created_at])

    # Optimize Unread Notifications lookup
    add_index :notifications, [:recipient_id, :read_at], algorithm: :concurrently unless index_exists?(:notifications, [:recipient_id, :read_at])

    # Optimize Posts by user and creation time for user profile feeds
    add_index :posts, [:user_id, :created_at], algorithm: :concurrently unless index_exists?(:posts, [:user_id, :created_at])
  end
end
