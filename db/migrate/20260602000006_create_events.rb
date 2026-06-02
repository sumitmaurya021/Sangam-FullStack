class CreateEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :events do |t|
      t.bigint  :organizer_id, null: false
      t.string  :title, null: false
      t.text    :description
      t.string  :location
      t.string  :privacy, default: 'public', null: false  # public | friends | private
      t.datetime :starts_at, null: false
      t.datetime :ends_at
      t.integer  :going_count,     default: 0, null: false
      t.integer  :interested_count, default: 0, null: false
      t.timestamps
    end
    add_index :events, :organizer_id
    add_index :events, :starts_at
    add_foreign_key :events, :users, column: :organizer_id

    create_table :event_responses do |t|
      t.references :event, null: false, foreign_key: true
      t.references :user,  null: false, foreign_key: true
      t.string :response, null: false  # going | interested | not_going
      t.timestamps
    end
    add_index :event_responses, [:event_id, :user_id], unique: true
  end
end
