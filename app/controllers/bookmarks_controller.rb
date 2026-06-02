class BookmarksController < ApplicationController
  def index
    @bookmarks = current_user.bookmarks
                             .includes(post: [:user, :likes, :comments])
                             .recent
                             .page(params[:page]).per(10)
    @posts = @bookmarks.map(&:post)
  end

  def create
    post = Post.find(params[:post_id])
    bookmark = current_user.bookmarks.find_or_initialize_by(post: post)

    if bookmark.new_record? && bookmark.save
      render json: { bookmarked: true, message: 'Post saved!' }
    else
      render json: { bookmarked: true, message: 'Already saved' }
    end
  end

  def destroy
    post = Post.find(params[:post_id])
    bookmark = current_user.bookmarks.find_by(post: post)

    if bookmark&.destroy
      render json: { bookmarked: false, message: 'Post unsaved' }
    else
      render json: { error: 'Bookmark not found' }, status: :not_found
    end
  end
end
