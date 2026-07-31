class AiRecommendationService
  def initialize(user)
    @user = user
  end

  def self.rank_posts_for(user, base_scope: Post.published, limit: 20)
    new(user).rank(base_scope: base_scope, limit: limit)
  end

  def rank(base_scope: Post.published, limit: 20)
    candidate_posts = base_scope.visible_to(@user).includes(:user, :likes, :comments).limit(50).to_a
    return [] if candidate_posts.empty?

    # 1. User interest centroid vector (average embedding of user's liked & interacted posts)
    user_centroid = compute_user_centroid

    # 2. Friend author IDs
    friend_ids = @user.all_friends.pluck(:id).to_set

    # 3. Score each post
    scored_posts = candidate_posts.map do |post|
      score, reason = calculate_post_score(post, user_centroid, friend_ids)
      { post: post, score: score, reason: reason }
    end.sort_by { |item| -item[:score] }.take(limit)

    scored_posts.map do |item|
      post = item[:post]
      # Attach recommendation metadata dynamically
      score_pct = [[(item[:score] * 20).round, 99].min, 60].max
      post.define_singleton_method(:recommendation_score_pct) { "#{score_pct}% Match" }
      post.define_singleton_method(:recommendation_reason) { item[:reason] }
      post
    end
  end

  private

  def compute_user_centroid
    liked_posts = Post.joins(:likes).where(likes: { user_id: @user.id }).limit(10)
    return Array.new(384, 0.0) if liked_posts.empty?

    embeddings = liked_posts.filter_map do |p|
      v = p.try(:embedding) || p.try(:embedding_data)
      v.present? ? AiEmbeddingService.parse_vector(v) : nil
    end

    return Array.new(384, 0.0) if embeddings.empty?

    # Average vectors
    dim = embeddings.first.length
    centroid = Array.new(dim, 0.0)
    embeddings.each do |vec|
      vec.each_with_index { |val, idx| centroid[idx] += val }
    end

    count = embeddings.length.to_f
    centroid.map { |val| (val / count).round(6) }
  end

  def calculate_post_score(post, user_centroid, friend_ids)
    score = 0.0
    reason = "Recommended for you"

    # A. Friend Boost (+2.5)
    if friend_ids.include?(post.user_id)
      score += 2.5
      reason = "From your friend #{post.user.name}"
    end

    # B. Vector Similarity Boost (+3.0)
    post_vec = post.try(:embedding) || post.try(:embedding_data)
    if post_vec.present? && user_centroid.any? { |v| v != 0.0 }
      sim = AiEmbeddingService.cosine_similarity(user_centroid, post_vec)
      score += (sim * 3.0)
      reason = "Matches your topic interests" if sim > 0.4
    end

    # C. Social Engagement Weight (+1.5)
    likes_cnt = post.likes_count.to_i
    comments_cnt = post.comments_count.to_i
    engagement = (likes_cnt * 0.5) + (comments_cnt * 1.0)
    score += [engagement * 0.2, 2.0].min

    # D. Time Decay Penalty
    hours_old = ((Time.current - post.created_at) / 3600.0).clamp(0.1, 168.0)
    decay = 1.0 / (1.0 + (hours_old / 24.0)) # Half-life ~24 hours
    score *= decay

    [score.round(4), reason]
  end
end
