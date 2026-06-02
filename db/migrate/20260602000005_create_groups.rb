class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.string  :name, null: false
      t.text    :description
      t.string  :privacy, default: 'public', null: false   # public | private | secret
      t.bigint  :owner_id, null: false
      t.integer :members_count, default: 0, null: false
      t.integer :posts_count,   default: 0, null: false
      t.timestamps
    end
    add_index :groups, :name
    add_index :groups, :owner_id
    add_foreign_key :groups, :users, column: :owner_id

    create_table :group_memberships do |t|
      t.references :group, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.string :role, default: 'member', null: false   # owner | admin | member
      t.string :status, default: 'active', null: false # active | pending | banned
      t.timestamps
    end
    add_index :group_memberships, [:group_id, :user_id], unique: true

    # Add group_id to posts (optional — group posts)
    add_column :posts, :group_id, :bigint
    add_index  :posts, :group_id
    add_foreign_key :posts, :groups, column: :group_id
  end
end
