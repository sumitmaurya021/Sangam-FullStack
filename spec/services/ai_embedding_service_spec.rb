require 'rails_helper'

RSpec.describe AiEmbeddingService do
  describe '#generate' do
    it 'generates a 384-dimensional normalized float vector' do
      service = AiEmbeddingService.new('Web development Ruby on Rails tutorial')
      vector = service.generate

      expect(vector).to be_an(Array)
      expect(vector.length).to eq(384)
      expect(vector.first).to be_a(Float)
    end
  end

  describe '.cosine_similarity' do
    it 'calculates similarity score between two vectors' do
      vec1 = AiEmbeddingService.new('Ruby programming language').generate
      vec2 = AiEmbeddingService.new('Ruby on Rails backend development').generate
      vec3 = AiEmbeddingService.new('Quantum astrophysics galaxy universe').generate

      sim_high = AiEmbeddingService.cosine_similarity(vec1, vec2)
      sim_low = AiEmbeddingService.cosine_similarity(vec1, vec3)

      expect(sim_high).to be > sim_low
      expect(sim_high).to be_between(0.0, 1.0)
    end
  end
end
