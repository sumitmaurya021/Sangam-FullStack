class CreateStories < ActiveRecord::Migration[8.1]
  def change
    create_table :stories do |t|
      t.references :user, null: false, foreign_key: true
      t.string  :story_type, default: 'image', null: false  # image | video | text
      t.text    :caption
      t.string  :background_color, default: '#1a1a2e'
      t.string  :text_color, default: '#ffffff'
      t.integer :views_count, default: 0, null: false
      t.datetime :expires_at, null: false
      t.timestamps
    end
    add_index :stories, :expires_at
    add_index :stories, [:user_id, :created_at]

    create_table :story_views do |t|
      t.references :story, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.timestamps
    end
    add_index :story_views, [:story_id, :user_id], unique: true
  end
end
