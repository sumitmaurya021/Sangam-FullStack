class DecayUserAffinitiesJob < ApplicationJob
  queue_as :default

  def perform
    # Multiply all scores by 0.95 to gradually decay old interests
    UserTagAffinity.update_all("score = score * 0.95")
  end
end
