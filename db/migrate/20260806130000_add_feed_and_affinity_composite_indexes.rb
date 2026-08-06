class AddFeedAndAffinityCompositeIndexes < ActiveRecord::Migration[8.1]
  disable_ddl_transaction!

  def change
    # Optimize Feed Candidate Sourcing Query
    unless index_exists?(:posts, [:visibility, :created_at])
      add_index :posts, [:visibility, :created_at], order: { created_at: :desc }, algorithm: :concurrently
    end

    # Optimize User Tag Affinities lookup
    unless index_exists?(:user_tag_affinities, [:user_id, :category_tag_id])
      add_index :user_tag_affinities, [:user_id, :category_tag_id], algorithm: :concurrently
    end

    # Optimize Close Friends lookup
    unless index_exists?(:close_friends, [:user_id, :close_friend_id])
      add_index :close_friends, [:user_id, :close_friend_id], algorithm: :concurrently
    end
  end
end
