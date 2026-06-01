class AddMusicFieldsToReels < ActiveRecord::Migration[8.1]
  def change
    add_column :reels, :music_title, :string
    add_column :reels, :music_artist, :string
    add_column :reels, :music_preview_url, :string
  end
end
