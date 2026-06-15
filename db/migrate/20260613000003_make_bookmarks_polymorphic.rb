class MakeBookmarksPolymorphic < ActiveRecord::Migration[8.1]
  def up
    # 1. Add polymorphic columns
    add_column :bookmarks, :bookmarkable_type, :string
    add_column :bookmarks, :bookmarkable_id,   :bigint

    # 2. Back-fill existing post bookmarks
    execute <<~SQL
      UPDATE bookmarks
      SET    bookmarkable_type = 'Post',
             bookmarkable_id   = post_id
      WHERE  post_id IS NOT NULL
    SQL

    # 3. Add polymorphic index
    add_index :bookmarks, [:bookmarkable_type, :bookmarkable_id],
              name: 'index_bookmarks_on_bookmarkable'

    # 4. Unique constraint: one bookmark per user per bookmarkable
    add_index :bookmarks, [:user_id, :bookmarkable_type, :bookmarkable_id],
              unique: true, name: 'index_bookmarks_unique_per_user'

    # 5. Make post_id nullable (it becomes legacy / kept for back-compat)
    change_column_null :bookmarks, :post_id, true
  end

  def down
    remove_index :bookmarks, name: 'index_bookmarks_on_bookmarkable'
    remove_index :bookmarks, name: 'index_bookmarks_unique_per_user'
    remove_column :bookmarks, :bookmarkable_type
    remove_column :bookmarks, :bookmarkable_id
    change_column_null :bookmarks, :post_id, false
  end
end
