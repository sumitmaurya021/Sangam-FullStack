class AddMusicAndHashtagsToReels < ActiveRecord::Migration[8.1]
  def change
    add_column :reels, :music_title,       :string unless column_exists?(:reels, :music_title)
    add_column :reels, :music_artist,      :string unless column_exists?(:reels, :music_artist)
    add_column :reels, :music_preview_url, :string unless column_exists?(:reels, :music_preview_url)
    add_column :reels, :hashtags,          :text   unless column_exists?(:reels, :hashtags)
    # Remove old music column if it exists
    remove_column :reels, :music, :string if column_exists?(:reels, :music)
  end
end
