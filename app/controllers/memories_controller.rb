# GET /memories — "On this day" feature
class MemoriesController < ApplicationController
  before_action :authenticate_user!

  def index
    today = Date.today
    @memories = current_user.posts
                             .where('EXTRACT(month FROM created_at) = ? AND EXTRACT(day FROM created_at) = ?',
                                    today.month, today.day)
                             .where('EXTRACT(year FROM created_at) < ?', today.year)
                             .includes(:likes, :comments, :user)
                             .order(created_at: :desc)

    respond_to do |format|
      format.html
      format.json do
        render json: {
          count:   @memories.count,
          memories: @memories.map { |p|
            {
              id:           p.id,
              content:      p.content&.truncate(200),
              years_ago:    today.year - p.created_at.year,
              created_at:   p.created_at.iso8601,
              likes_count:  p.likes_count,
              comments_count: p.comments_count
            }
          }
        }
      end
    end
  end
end
