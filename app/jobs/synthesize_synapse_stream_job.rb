class SynthesizeSynapseStreamJob < ApplicationJob
  queue_as :default

  def perform(synapse_stream_id)
    stream = SynapseStream.find_by(id: synapse_stream_id)
    return unless stream

    SynapseStreamSynthesisService.new(stream).synthesize!
  end
end
