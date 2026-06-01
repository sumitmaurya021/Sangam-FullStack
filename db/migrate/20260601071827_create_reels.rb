class CreateReels < ActiveRecord::Migration[8.1]
  def change
    create_table :reels do |t|
      t.bigint :user_id, null: false
      t.text :caption
      t.integer :views_count, default: 0, null: false
      t.integer :likes_count, default: 0, null: false
      t.integer :comments_count, default: 0, null: false
      t.integer :duration
      t.timestamps
    end

    add_index :reels, :user_id
    add_index :reels, :created_at
    add_foreign_key :reels, :users
  end
end
