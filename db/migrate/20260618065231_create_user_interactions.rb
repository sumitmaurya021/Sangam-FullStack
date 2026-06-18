class CreateUserInteractions < ActiveRecord::Migration[8.1]
  def change
    create_table :user_interactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.integer :interaction_type

      t.timestamps
    end
  end
end
