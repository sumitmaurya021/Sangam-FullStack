class CreateReelComments < ActiveRecord::Migration[8.1]
  def change
    create_table :reel_comments do |t|
      t.bigint :reel_id, null: false
      t.bigint :user_id, null: false
      t.text :content, null: false
      t.bigint :parent_id
      t.integer :replies_count, default: 0, null: false
      t.timestamps
    end

    add_index :reel_comments, :reel_id
    add_index :reel_comments, :user_id
    add_index :reel_comments, :parent_id
    add_foreign_key :reel_comments, :reels
    add_foreign_key :reel_comments, :users
    add_foreign_key :reel_comments, :reel_comments, column: :parent_id
  end
end
