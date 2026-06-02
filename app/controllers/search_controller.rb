class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @type  = params[:type].presence || 'all'

    if @query.length < 2
      @users    = User.none
      @posts    = Post.none
      @hashtags = Hashtag.none
      @groups   = Group.none
      @events   = Event.none
      return
    end

    case @type
    when 'people'
      @users = search_users
    when 'posts'
      @posts = search_posts
    when 'hashtags'
      @hashtags = search_hashtags
    when 'groups'
      @groups = search_groups
    when 'events'
      @events = search_events
    else
      # All
      @users    = search_users.limit(5)
      @posts    = search_posts.limit(8)
      @hashtags = search_hashtags.limit(10)
      @groups   = search_groups.limit(5)
      @events   = search_events.limit(5)
    end

    respond_to do |format|
      format.html
      format.json { render json: build_json_response }
    end
  end

  private

  def search_users
    User.where.not(id: current_user.id)
        .where("name ILIKE :q OR email ILIKE :q", q: "%#{@query}%")
        .order(:name)
        .limit(20)
  end

  def search_posts
    Post.visible_to(current_user)
        .search(@query)
        .includes(:user, :likes, :comments)
        .order(created_at: :desc)
        .limit(20)
  end

  def search_hashtags
    Hashtag.search(@query).order(posts_count: :desc).limit(20)
  end

  def search_groups
    Group.public_groups.search(@query).order(members_count: :desc).limit(20)
  end

  def search_events
    Event.upcoming.search(@query).where(privacy: 'public').order(:starts_at).limit(20)
  end

  def build_json_response
    {
      query: @query,
      users: (@users || []).map { |u|
        {
          id:     u.id,
          name:   u.name,
          avatar: u.avatar.attached? ? url_for(u.avatar) : nil,
          profile_url: profile_path(u)
        }
      },
      posts: (@posts || []).map { |p|
        { id: p.id, content: p.content.truncate(100), user: p.user.name }
      },
      hashtags: (@hashtags || []).map { |h|
        { id: h.id, name: "##{h.name}", posts_count: h.posts_count }
      },
      groups: (@groups || []).map { |g|
        { id: g.id, name: g.name, members_count: g.members_count }
      },
      events: (@events || []).map { |e|
        { id: e.id, title: e.title, starts_at: e.starts_at.strftime('%b %d, %Y') }
      }
    }
  end
end
