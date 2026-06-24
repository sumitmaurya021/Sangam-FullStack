class FeedRankingService
  # Weights configuration
  WEIGHTS = {
    tag_affinity: 0.40,
    engagement: 0.25,
    recency: 0.20,
    following_boost: 0.10,
    random: 0.05
  }.freeze

  def initialize(user)
    @user = user
  end

  def get_feed(page = 1, per_page = 5)
    # Check cache
    cache_key = "feed_ranking:#{@user.id}:page:#{page}:per_page:#{per_page}"
    cached_post_ids = Rails.cache.read(cache_key)

    if cached_post_ids
      posts = Post.where(id: cached_post_ids).includes(
        :user, :likes, :comments, :shares, :hashtags, :poll, :fundraiser, :bookmarks,
        { post_collaborators: :user },
        { user: { avatar_attachment: :blob } },
        { images_attachments: :blob },
        { image_attachment: :blob }
      )
      # Sort based on the exact cached array order
      posts = posts.sort_by { |p| cached_post_ids.index(p.id) }
      return Kaminari.paginate_array(posts, total_count: total_candidate_count).page(page).per(per_page)
    end

    # 1. Candidate Sourcing
    # - Recent posts from friends (last 7 days)
    # - Recent posts matching top 5 affinities
    # - Random explore slice
    candidate_posts = fetch_candidates

    # 2. Scoring
    user_affinities = fetch_user_affinities
    friend_ids = @user.all_friends.pluck(:id)
    close_friend_ids = @user.close_friend_records.pluck(:close_friend_id)

    scored_posts = candidate_posts.map do |post|
      score = calculate_score(post, user_affinities, friend_ids, close_friend_ids)
      { post: post, score: score }
    end

    # 3. Sorting and Re-ranking
    scored_posts.sort_by! { |p| -p[:score] }
    
    # Simple re-rank to cap consecutive authors
    final_post_ids = apply_rerank(scored_posts).map { |p| p[:post].id }
    
    # Slice the page
    start_idx = (page.to_i - 1) * per_page
    page_ids = final_post_ids[start_idx, per_page] || []

    # Cache the whole list of ids
    Rails.cache.write(cache_key, page_ids, expires_in: 5.minutes)
    @total_count = final_post_ids.count

    posts = Post.where(id: page_ids).includes(
      :user, :likes, :comments, :shares, :hashtags, :poll, :fundraiser, :bookmarks,
      { post_collaborators: :user },
      { user: { avatar_attachment: :blob } },
      { images_attachments: :blob },
      { image_attachment: :blob }
    )
    posts = posts.sort_by { |p| page_ids.index(p.id) }
    
    Kaminari.paginate_array(posts, total_count: @total_count).page(page).per(per_page)
  end

  private

  def total_candidate_count
    @total_count || fetch_candidates.count
  end

  def fetch_candidates
    # Optimization: Just get recent posts visible to user for now.
    # In a real app with lots of data, we would filter by last 7 days: `.where("posts.created_at > ?", 7.days.ago)`
    Post.visible_to(@user).order(created_at: :desc).limit(200)
  end

  def fetch_user_affinities
    UserTagAffinity.where(user: @user).each_with_object({}) do |affinity, hash|
      hash[affinity.category_tag_id] = affinity.score
    end
  end

  def calculate_score(post, user_affinities, friend_ids, close_friend_ids)
    # A. Tag Affinity Score
    affinity_score = 0.0
    post.post_category_tags.each do |pct|
      user_score = user_affinities[pct.category_tag_id] || 0.0
      affinity_score += (user_score * pct.confidence_score)
    end
    # Normalize roughly (0 to 10 scale hypothetically)
    affinity_score = [affinity_score, 10.0].min / 10.0

    # B. Engagement Rate (Likes + Comments*2 + Shares*3) / Impressions (using views_count)
    impressions = [post.views_count, 1].max
    engagement_val = (post.likes_count * 1) + (post.comments_count * 2) + (post.shares_count * 3)
    engagement_rate = (engagement_val.to_f / impressions.to_f)
    engagement_rate = [engagement_rate, 1.0].min # cap at 1.0

    # C. Recency Score (1 / (1 + hours))
    hours_since = (Time.current - post.created_at) / 1.hour
    recency_score = 1.0 / (1.0 + hours_since)

    # D. Following Boost
    following_boost = 0.0
    if close_friend_ids.include?(post.user_id)
      following_boost = 1.0
    elsif friend_ids.include?(post.user_id)
      following_boost = 0.8
    elsif post.user_id == @user.id
      following_boost = 1.0
    end

    # E. Random Exploration
    random_score = rand

    final = (WEIGHTS[:tag_affinity] * affinity_score) +
            (WEIGHTS[:engagement] * engagement_rate) +
            (WEIGHTS[:recency] * recency_score) +
            (WEIGHTS[:following_boost] * following_boost) +
            (WEIGHTS[:random] * random_score)

    final
  end

  def apply_rerank(scored_posts)
    # Cap 2 consecutive posts from same author
    final_list = []
    consecutive_counts = Hash.new(0)
    last_author_id = nil

    scored_posts.each do |item|
      author_id = item[:post].user_id
      
      if author_id == last_author_id
        consecutive_counts[author_id] += 1
      else
        consecutive_counts[author_id] = 1
        last_author_id = author_id
      end

      if consecutive_counts[author_id] <= 2
        final_list << item
      else
        # Skip this post for now (in a real system we might buffer it and insert later)
      end
    end

    final_list
  end
end
