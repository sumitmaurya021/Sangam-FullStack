class AddVisibilityToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :visibility, :string, default: 'public', null: false
    add_column :posts, :edited_at, :datetime
    add_index :posts, :visibility
  end
end
