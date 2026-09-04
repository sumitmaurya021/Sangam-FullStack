module AiModeratable
  extend ActiveSupport::Concern

  def moderate_content!(text, target_type: nil, target_id: nil)
    return { status: :approved } if text.blank?

    result = AiModerationService.new(text, user: current_user, target_type: target_type, target_id: target_id).analyze

    case result[:action_taken]
    when "blocked"
      { status: :blocked, reason: result[:reason] || "Content flagged by AI Safety Guard for toxicity or inappropriate language." }
    when "flagged_for_review"
      { status: :flagged_for_review, reason: result[:reason] || "Content flagged for moderator review." }
    else
      { status: :approved }
    end
  end
end
