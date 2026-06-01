class CreateReelLikes < ActiveRecord::Migration[8.1]
  def change
    create_table :reel_likes do |t|
      t.bigint :reel_id, null: false
      t.bigint :user_id, null: false
      t.string :reaction_type, default: 'like', null: false
      t.timestamps
    end

    add_index :reel_likes, :reel_id
    add_index :reel_likes, :user_id
    add_index :reel_likes, [:reel_id, :user_id], unique: true
    add_index :reel_likes, :reaction_type
    add_foreign_key :reel_likes, :reels
    add_foreign_key :reel_likes, :users
  end
end
