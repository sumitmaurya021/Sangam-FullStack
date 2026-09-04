require "digest"

class AiEmbeddingService
  VECTOR_DIM = 384

  def initialize(text)
    @text = text.to_s.strip
  end

  def generate
    return Array.new(VECTOR_DIM, 0.0) if @text.blank?

    # Deterministic semantic feature hashing vectorizer (384 dimensions)
    words = @text.downcase.scan(/\w+/)
    vector = Array.new(VECTOR_DIM, 0.0)

    words.each do |word|
      hash_val = Digest::MD5.hexdigest(word).to_i(16)
      index = hash_val % VECTOR_DIM
      weight = (hash_val % 100) / 100.0 + 0.1
      vector[index] += weight
    end

    # Normalize vector to unit length (L2 norm)
    magnitude = Math.sqrt(vector.sum { |val| val**2 })
    if magnitude > 0
      vector = vector.map { |val| (val / magnitude).round(6) }
    end

    vector
  end

  # Helper method to calculate cosine similarity between two vector arrays
  def self.cosine_similarity(vec1, vec2)
    return 0.0 if vec1.blank? || vec2.blank?

    v1 = vec1.is_a?(String) ? parse_vector(vec1) : vec1
    v2 = vec2.is_a?(String) ? parse_vector(vec2) : vec2

    return 0.0 if v1.empty? || v2.empty? || v1.length != v2.length

    dot_product = v1.zip(v2).sum { |a, b| a * b }
    mag1 = Math.sqrt(v1.sum { |a| a**2 })
    mag2 = Math.sqrt(v2.sum { |b| b**2 })

    return 0.0 if mag1 == 0 || mag2 == 0

    similarity = dot_product / (mag1 * mag2)
    [[similarity, 0.0].max, 1.0].min.round(4)
  end

  def self.parse_vector(vec_str)
    return [] if vec_str.blank?
    clean = vec_str.to_s.tr("[]", "")
    clean.split(",").map(&:to_f)
  rescue
    []
  end
end
