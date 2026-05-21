class AddMultipleImagesToPosts < ActiveRecord::Migration[8.1]
  def change
    # Note: Active Storage will handle multiple images
    # We just need to ensure the association is set up in the model
    # No migration needed for Active Storage attachments
  end
end
