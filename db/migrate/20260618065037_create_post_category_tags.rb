class CreatePostCategoryTags < ActiveRecord::Migration[8.1]
  def change
    create_table :post_category_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :category_tag, null: false, foreign_key: true
      t.float :confidence_score

      t.timestamps
    end
  end
end
