class AddModerationToPostsAndComments < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :flagged, :boolean, default: false, null: false
    add_column :posts, :flag_reason, :string

    add_column :comments, :flagged, :boolean, default: false, null: false
    add_column :comments, :flag_reason, :string

    add_index :posts, :flagged
    add_index :comments, :flagged
  end
end
