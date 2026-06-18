class CreateCategoryTags < ActiveRecord::Migration[8.1]
  def change
    create_table :category_tags do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :category_tags, :slug, unique: true
  end
end
