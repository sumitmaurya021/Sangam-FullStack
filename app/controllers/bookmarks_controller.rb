class BookmarksController < ApplicationController
  # GET /bookmarks  — shows both saved posts and reels, tabbed
  def index
    @post_bookmarks = current_user.bookmarks
                                  .for_posts
                                  .includes(bookmarkable: [:user, :likes, :comments])
                                  .recent
                                  .page(params[:page]).per(10)
    @saved_posts = @post_bookmarks.map(&:bookmarkable)

    @reel_bookmarks = current_user.bookmarks
                                  .for_reels
                                  .includes(bookmarkable: [:user, :reel_likes, :reel_comments])
                                  .recent
    @saved_reels = @reel_bookmarks.map(&:bookmarkable)

    @active_tab = params[:tab] == 'reels' ? 'reels' : 'posts'
  end

  # POST /posts/:post_id/bookmark
  def create
    bookmarkable = find_bookmarkable
    return render_not_found unless bookmarkable

    bookmark = current_user.bookmarks.find_or_initialize_by(
      bookmarkable_type: bookmarkable.class.name,
      bookmarkable_id:   bookmarkable.id
    )
    # Also stamp post_id for legacy FK when bookmarking a post
    bookmark.post_id = bookmarkable.id if bookmarkable.is_a?(Post)

    if bookmark.new_record? && bookmark.save
      render json: { bookmarked: true, message: "#{bookmarkable.class.name} saved!" }
    else
      render json: { bookmarked: true, message: 'Already saved' }
    end
  end

  # DELETE /posts/:post_id/unbookmark  OR  DELETE /reels/:reel_id/unbookmark_reel
  def destroy
    bookmarkable = find_bookmarkable
    return render_not_found unless bookmarkable

    bookmark = current_user.bookmarks.find_by(
      bookmarkable_type: bookmarkable.class.name,
      bookmarkable_id:   bookmarkable.id
    )

    if bookmark&.destroy
      render json: { bookmarked: false, message: "#{bookmarkable.class.name} unsaved" }
    else
      render json: { error: 'Bookmark not found' }, status: :not_found
    end
  end

  private

  # Resolve the bookmarkable from params — supports post_id and reel_id
  def find_bookmarkable
    if params[:post_id].present?
      Post.find_by(id: params[:post_id])
    elsif params[:reel_id].present?
      Reel.find_by(id: params[:reel_id])
    end
  end

  def render_not_found
    render json: { error: 'Not found' }, status: :not_found
  end
end
