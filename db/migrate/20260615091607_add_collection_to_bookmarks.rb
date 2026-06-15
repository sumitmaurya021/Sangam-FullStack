class AddCollectionToBookmarks < ActiveRecord::Migration[8.1]
  def change
    add_reference :bookmarks, :bookmark_collection, foreign_key: true, null: true
  end
end
