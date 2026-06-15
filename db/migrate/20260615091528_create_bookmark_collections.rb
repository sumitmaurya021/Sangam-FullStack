class CreateBookmarkCollections < ActiveRecord::Migration[8.1]
  def change
    create_table :bookmark_collections do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :name,        null: false
      t.text    :description
      t.boolean :is_default,  null: false, default: false
      t.integer :cover_item_id   # optional: store one bookmark id for cover thumbnail

      t.timestamps
    end

    add_index :bookmark_collections, [:user_id, :name], unique: true
  end
end
