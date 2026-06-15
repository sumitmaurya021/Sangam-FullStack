# Handles all 2FA flows:
#   GET  /two_factor_auth/setup       — show QR + secret (first-time enable)
#   POST /two_factor_auth/enable      — verify code, save secret, mark enabled
#   DELETE /two_factor_auth/disable   — turn off 2FA (requires code confirm)
#   GET  /two_factor_auth/verify      — OTP entry page after password login
#   POST /two_factor_auth/confirm     — validate OTP during login
class TwoFactorAuthController < ApplicationController
  # verify action is hit before the session is fully established
  skip_before_action :authenticate_user!, only: [:verify, :confirm]
  before_action :require_pending_2fa!, only: [:verify, :confirm]
  before_action :authenticate_user!,   only: [:setup, :enable, :disable]

  # ─── Setup: generate provisional secret + show QR ─────────────────────────
  # GET /two_factor_auth/setup
  def setup
    # Generate a fresh provisional secret each visit (not saved yet)
    @provisional_secret = ROTP::Base32.random
    session[:provisional_2fa_secret] = @provisional_secret

    issuer   = 'Sangam'
    label    = CGI.escape("#{issuer}:#{current_user.email}")
    totp_uri = ROTP::TOTP.new(@provisional_secret, issuer: issuer)
                         .provisioning_uri(current_user.email)

    @qr_svg  = RQRCode::QRCode.new(totp_uri).as_svg(
      offset: 0, color: '000', shape_rendering: 'crispEdges',
      module_size: 5, standalone: true
    )
  end

  # ─── Enable: verify provisional code, store secret ────────────────────────
  # POST /two_factor_auth/enable
  def enable
    provisional = session[:provisional_2fa_secret]

    unless provisional.present?
      return redirect_to setup_two_factor_auth_path,
                         alert: 'Session expired. Please start again.'
    end

    totp = ROTP::TOTP.new(provisional, issuer: 'Sangam')

    if totp.verify(params[:otp_code].to_s.strip.gsub(/\s/, ''), drift_behind: 30)
      backup_codes = generate_backup_codes

      current_user.update!(
        otp_secret:       provisional,
        otp_enabled:      true,
        otp_backup_codes: backup_codes.to_json
      )
      session.delete(:provisional_2fa_secret)

      # Show backup codes once — stored hashed in production ideally,
      # but plaintext here for simplicity (same as GitHub's approach at setup)
      flash[:backup_codes] = backup_codes
      redirect_to edit_user_registration_path,
                  notice: '2FA enabled successfully! Save your backup codes.'
    else
      redirect_to setup_two_factor_auth_path,
                  alert: 'Invalid code. Please try again — make sure your clock is synced.'
    end
  end

  # ─── Disable: turn off 2FA ─────────────────────────────────────────────────
  # DELETE /two_factor_auth/disable
  def disable
    totp = ROTP::TOTP.new(current_user.otp_secret, issuer: 'Sangam')

    if totp.verify(params[:otp_code].to_s.strip.gsub(/\s/, ''), drift_behind: 30)
      current_user.update!(
        otp_secret:       nil,
        otp_enabled:      false,
        otp_backup_codes: nil
      )
      redirect_to edit_user_registration_path,
                  notice: '2FA has been disabled.'
    else
      redirect_to edit_user_registration_path,
                  alert: 'Invalid code. 2FA was not disabled.'
    end
  end

  # ─── Verify: OTP entry page shown after successful password auth ───────────
  # GET /two_factor_auth/verify
  def verify
    # nothing to render — just the form
  end

  # ─── Confirm: validate OTP during login ────────────────────────────────────
  # POST /two_factor_auth/confirm
  def confirm
    user = User.find_by(id: session[:pending_2fa_user_id])

    unless user&.otp_enabled?
      session.delete(:pending_2fa_user_id)
      return redirect_to new_user_session_path, alert: 'Session expired. Please sign in again.'
    end

    code  = params[:otp_code].to_s.strip.gsub(/\s/, '')
    totp  = ROTP::TOTP.new(user.otp_secret, issuer: 'Sangam')
    valid = totp.verify(code, drift_behind: 30)

    # Also accept backup codes (each usable only once)
    unless valid
      valid = verify_backup_code!(user, code)
    end

    if valid
      session.delete(:pending_2fa_user_id)
      sign_in(user)
      redirect_to root_path, notice: 'Signed in successfully.'
    else
      flash.now[:alert] = 'Invalid code. Please try again.'
      render :verify, status: :unprocessable_entity
    end
  end

  private

  # Ensure we're in the middle of a 2FA challenge
  def require_pending_2fa!
    unless session[:pending_2fa_user_id].present?
      redirect_to new_user_session_path
    end
  end

  # Generate 8 alphanumeric backup codes
  def generate_backup_codes
    Array.new(8) { SecureRandom.hex(4).upcase.insert(4, '-') }
  end

  # Check supplied code against stored backup codes (consume on use)
  def verify_backup_code!(user, code)
    codes = JSON.parse(user.otp_backup_codes.presence || '[]')
    normalized_code = code.upcase.gsub(/[^A-Z0-9\-]/, '')

    if codes.include?(normalized_code)
      remaining = codes - [normalized_code]
      user.update_column(:otp_backup_codes, remaining.to_json)
      return true
    end
    false
  rescue JSON::ParserError
    false
  end
end
