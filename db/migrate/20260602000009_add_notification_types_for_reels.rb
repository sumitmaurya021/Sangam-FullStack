class AddNotificationTypesForReels < ActiveRecord::Migration[8.1]
  # No schema change needed — notification_type is just a string column.
  # This migration documents the intent and can be used for data backfills.
  def change
    # Add index for faster reel notification queries
    add_index :notifications, :notification_type, name: 'index_notifications_on_type_extended', if_not_exists: true
  end
end
