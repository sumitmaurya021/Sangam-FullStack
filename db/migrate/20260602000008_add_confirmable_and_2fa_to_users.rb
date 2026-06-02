class AddConfirmableAnd2faToUsers < ActiveRecord::Migration[8.1]
  def change
    # Devise :confirmable columns
    add_column :users, :confirmation_token,   :string
    add_column :users, :confirmed_at,         :datetime
    add_column :users, :confirmation_sent_at, :datetime
    add_column :users, :unconfirmed_email,    :string

    # Devise :lockable columns
    add_column :users, :failed_attempts,    :integer, default: 0, null: false
    add_column :users, :unlock_token,       :string
    add_column :users, :locked_at,          :datetime

    # OmniAuth columns
    add_column :users, :provider, :string
    add_column :users, :uid,      :string

    # 2FA (TOTP-based)
    add_column :users, :otp_secret,           :string
    add_column :users, :otp_enabled,          :boolean, default: false, null: false
    add_column :users, :otp_backup_codes,     :text    # JSON array

    add_index :users, :confirmation_token, unique: true
    add_index :users, :unlock_token,       unique: true
    add_index :users, [:provider, :uid],   unique: true
  end
end
