class CreateUserTagAffinities < ActiveRecord::Migration[8.1]
  def change
    create_table :user_tag_affinities do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category_tag, null: false, foreign_key: true
      t.float :score

      t.timestamps
    end
  end
end
