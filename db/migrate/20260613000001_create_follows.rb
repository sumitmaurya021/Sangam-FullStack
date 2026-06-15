class CreateFollows < ActiveRecord::Migration[8.1]
  def change
    create_table :follows do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }, index: true
      t.references :followee, null: false, foreign_key: { to_table: :users }, index: true
      t.timestamps
    end

    # Prevent duplicate follows
    add_index :follows, [:follower_id, :followee_id], unique: true

    # Follower / following counter caches on users
    add_column :users, :followers_count,  :integer, null: false, default: 0
    add_column :users, :following_count,  :integer, null: false, default: 0
  end
end
