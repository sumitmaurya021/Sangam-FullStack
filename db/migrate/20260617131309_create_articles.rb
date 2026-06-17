class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles do |t|
      t.string :title
      t.references :user, null: false, foreign_key: true
      t.integer :views_count, default: 0, null: false
      t.boolean :published, default: true, null: false

      t.timestamps
    end
  end
end
