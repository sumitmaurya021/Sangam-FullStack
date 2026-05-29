class AddRepliedToUserIdToComments < ActiveRecord::Migration[8.1]
  def change
    add_column :comments, :replied_to_user_id, :bigint
    add_index :comments, :replied_to_user_id
    add_foreign_key :comments, :users, column: :replied_to_user_id
  end
end
