class AddSharedPostToStories < ActiveRecord::Migration[8.1]
  def change
    # Reference to the original post that was shared as a story
    add_reference :stories, :shared_post, null: true, foreign_key: { to_table: :posts }, index: true
    # Convenience flag so we can quickly scope to "shared" stories
    add_column :stories, :is_shared_post, :boolean, null: false, default: false
    add_index  :stories, :is_shared_post
  end
end
