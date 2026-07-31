class DigitalTwin < ApplicationRecord
  belongs_to :user
  has_many :digital_twin_logs, dependent: :destroy

  validates :mode, inclusion: { in: %w[always_on away_only scheduled] }
  validates :persona_name, presence: true

  # Check if digital twin should trigger for a given source and online state
  def should_trigger?(source, recipient_online: false)
    return false unless enabled?

    case mode
    when "always_on"
      # Runs regardless of user online status
    when "away_only"
      return false if recipient_online
    when "scheduled"
      # Default behavior for scheduled mode
    end

    case source.to_s
    when "direct_message"
      auto_reply_dms?
    when "marketplace"
      auto_reply_marketplace?
    when "group_chat"
      auto_reply_group_chats?
    else
      false
    end
  end

  # Check if input violates safety guardrails
  def violates_guardrails?(input_text)
    return false if input_text.blank?
    text = input_text.downcase

    guardrail_config = guardrails || {}
    flagged_topics = guardrail_config["flag_topics"] || ["password", "bank", "address", "ssn"]

    flagged_topics.any? { |topic| text.include?(topic.downcase) }
  end
end
