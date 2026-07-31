class UxMutationPreference < ApplicationRecord
  belongs_to :user

  VALID_LAYOUT_MODES = %w[standard minimalist power_density voice_first].freeze

  validates :layout_mode, inclusion: { in: VALID_LAYOUT_MODES }

  scope :auto_adaptable, -> { where(auto_adapt: true) }

  # Human-readable mode title
  def mode_title
    case layout_mode
    when "minimalist"
      "✨ Minimalist Studio (Simplified UI)"
    when "power_density"
      "⚡ Power Density (High Data Density)"
    when "voice_first"
      "🎙️ Voice-First AI (Audio Input Focused)"
    else
      "🌐 Standard Adaptive"
    end
  end
end
