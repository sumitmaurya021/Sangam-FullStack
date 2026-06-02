class CreatePostMentions < ActiveRecord::Migration[8.1]
  def change
    create_table :post_mentions do |t|
      t.references :post,    null: false, foreign_key: true
      t.references :user,    null: false, foreign_key: true
      t.string     :mentionable_type  # 'Post' or 'Comment'
      t.bigint     :mentionable_id
      t.timestamps
    end
    add_index :post_mentions, [:post_id, :user_id], unique: true
    add_index :post_mentions, [:mentionable_type, :mentionable_id]
  end
end
