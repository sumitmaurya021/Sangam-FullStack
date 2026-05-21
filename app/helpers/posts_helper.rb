module PostsHelper
  def reaction_emoji_for(reaction_type)
    Like::REACTIONS[reaction_type] || '👍'
  end
  
  def post_image_grid_class(images_count)
    "grid-#{[images_count, 5].min}"
  end
  
  def format_reaction_count(count)
    return count.to_s if count < 1000
    return "#{(count / 1000.0).round(1)}K" if count < 1_000_000
    "#{(count / 1_000_000.0).round(1)}M"
  end
end
