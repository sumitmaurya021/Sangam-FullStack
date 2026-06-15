require 'rails_helper'

RSpec.describe User, type: :model do
  let(:user) { create(:user) }

  describe '#two_factor_enabled?' do
    it 'returns false by default' do
      expect(user.two_factor_enabled?).to be false
    end

    it 'returns true when otp_enabled and otp_secret are set' do
      user.update!(otp_secret: ROTP::Base32.random, otp_enabled: true)
      expect(user.two_factor_enabled?).to be true
    end

    it 'returns false when otp_enabled but no secret' do
      user.update_columns(otp_enabled: true, otp_secret: nil)
      expect(user.two_factor_enabled?).to be false
    end
  end

  describe '#valid_otp?' do
    let(:secret) { ROTP::Base32.random }
    before { user.update!(otp_secret: secret, otp_enabled: true) }

    it 'returns true for a valid current TOTP code' do
      code = ROTP::TOTP.new(secret).now
      expect(user.valid_otp?(code)).to be_truthy
    end

    it 'returns false for a wrong code' do
      expect(user.valid_otp?('000000')).to be_falsy
    end

    it 'returns false when 2FA is not enabled' do
      user.update!(otp_enabled: false)
      code = ROTP::TOTP.new(secret).now
      expect(user.valid_otp?(code)).to be false
    end

    it 'strips spaces from the code before verifying' do
      code = ROTP::TOTP.new(secret).now
      spaced_code = code.insert(3, ' ')
      expect(user.valid_otp?(spaced_code)).to be_truthy
    end
  end

  describe 'DB columns for 2FA' do
    it 'has otp_secret, otp_enabled, otp_backup_codes columns' do
      expect(user).to respond_to(:otp_secret)
      expect(user).to respond_to(:otp_enabled)
      expect(user).to respond_to(:otp_backup_codes)
    end

    it 'otp_enabled defaults to false' do
      expect(user.otp_enabled).to be false
    end
  end
end
