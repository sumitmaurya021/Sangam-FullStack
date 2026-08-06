class AddHnswIndexesAndUserCounterCaches < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Add unread notifications counter cache to Users
    unless column_exists?(:users, :unread_notifications_count)
      add_column :users, :unread_notifications_count, :integer, default: 0, null: false
    end

    # HNSW Vector Index on posts for ultra-fast vector similarity searches if vector column exists
    if vector_column_exists?
      execute <<~SQL
        CREATE INDEX CONCURRENTLY IF NOT EXISTS index_posts_on_embedding_hnsw
        ON posts USING hnsw (embedding vector_cosine_ops);
      SQL
    end
  end

  private

  def vector_column_exists?
    column_exists?(:posts, :embedding)
  rescue
    false
  end
end
