class AddIsAiToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :is_ai, :boolean, default: false
  end
end
