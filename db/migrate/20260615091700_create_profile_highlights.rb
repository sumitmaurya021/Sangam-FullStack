class CreateProfileHighlights < ActiveRecord::Migration[8.1]
  def change
    create_table :profile_highlights do |t|
      t.references :user,  null: false, foreign_key: true
      t.string :name,      null: false
      t.string :emoji,     default: '⭐'
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :profile_highlights, [:user_id, :name], unique: true

    # Join table: which stories belong to which highlight
    create_table :highlight_stories do |t|
      t.references :profile_highlight, null: false, foreign_key: true
      t.references :story,             null: false, foreign_key: true
      t.integer    :position,          default: 0, null: false
      t.timestamps
    end

    add_index :highlight_stories, [:profile_highlight_id, :story_id], unique: true
  end
end
