module ApplicationHelper
  def meta_tags(tags = {})
    @meta_tags ||= {}
    @meta_tags.merge!(tags)
  end

  def render_meta_tags
    defaults = {
      title: "Sangam",
      description: "Sangam - A modern full-stack social network linking people, groups, and events.",
      image: request.base_url + "/icon.svg",
      url: request.original_url,
      type: "website",
      twitter_card: "summary_large_image"
    }

    tags = defaults.merge(@meta_tags || {})

    capture do
      concat tag.meta(name: "description", content: tags[:description])
      concat tag.meta(property: "og:title", content: tags[:title])
      concat tag.meta(property: "og:description", content: tags[:description])
      concat tag.meta(property: "og:image", content: tags[:image])
      concat tag.meta(property: "og:url", content: tags[:url])
      concat tag.meta(property: "og:type", content: tags[:type])
      concat tag.meta(name: "twitter:card", content: tags[:twitter_card])
      concat tag.meta(name: "twitter:title", content: tags[:title])
      concat tag.meta(name: "twitter:description", content: tags[:description])
      concat tag.meta(name: "twitter:image", content: tags[:image])
    end
  end

  # High-performance user avatar tag using ActiveStorage thumbnail variants
  def user_avatar_tag(user, size: :thumb, class_name: "", alt: nil, loading: "lazy")
    return tag.div("U", class: "avatar-placeholder #{class_name}") unless user

    if user.avatar.attached?
      variant = user.avatar.variable? ? user.avatar.variant(size) : user.avatar
      image_tag variant, alt: (alt || "#{user.display_name} avatar"), class: class_name, loading: loading
    else
      initial = (user.name.presence || user.email.presence || "U").first.upcase
      tag.div(initial, class: "avatar-placeholder #{class_name}")
    end
  rescue => e
    tag.div((user&.name || "U").first.upcase, class: "avatar-placeholder #{class_name}")
  end
end
