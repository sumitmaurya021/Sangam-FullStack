class AddMusicAndHashtagsToReels < ActiveRecord::Migration[8.1]
  def change
    add_column :reels, :music_title,       :string
    add_column :reels, :music_artist,      :string
    add_column :reels, :music_preview_url, :string
    add_column :reels, :hashtags,          :text
    # Remove old music column if it exists
    remove_column :reels, :music, :string if column_exists?(:reels, :music)
  end
end
