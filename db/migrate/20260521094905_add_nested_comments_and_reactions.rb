class AddNestedCommentsAndReactions < ActiveRecord::Migration[8.1]
  def change
    # Add parent_id to comments for nested comments
    add_reference :comments, :parent, foreign_key: { to_table: :comments }, null: true
    add_column :comments, :replies_count, :integer, default: 0, null: false
    
    # Add reaction_type to likes (like, love, haha, wow, sad, angry)
    add_column :likes, :reaction_type, :string, default: 'like', null: false
    add_index :likes, :reaction_type
  end
end
