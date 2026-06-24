class BookmarkCollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection, only: [:show, :update, :destroy]

  # GET /bookmark_collections
  def index
    @collections = current_user.bookmark_collections.ordered
    respond_to do |format|
      format.html # renders index.html.erb
      format.json do
        render json: @collections.map { |c|
          {
            id:     c.id,
            name:   c.name,
            count:  c.bookmarks_count,
            cover:  c.cover_thumbnail_url(Rails.application.routes.url_helpers),
            default: c.is_default
          }
        }
      end
    end
  end

  # GET /bookmark_collections/:id
  def show
    @bookmarks = @collection.bookmarks
                             .includes(:bookmarkable)
                             .recent
                             .page(params[:page]).per(12)

    respond_to do |format|
      format.html
      format.json { render json: collection_json(@collection) }
    end
  end

  # POST /bookmark_collections
  def create
    @collection = current_user.bookmark_collections.build(collection_params)
    if @collection.save
      render json: { success: true, collection: collection_summary(@collection) }, status: :created
    else
      render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PATCH /bookmark_collections/:id
  def update
    if @collection.update(collection_params)
      render json: { success: true, collection: collection_summary(@collection) }
    else
      render json: { errors: @collection.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /bookmark_collections/:id
  def destroy
    if @collection.is_default
      render json: { error: "Can't delete the default collection" }, status: :forbidden
    else
      @collection.destroy
      render json: { success: true }
    end
  end

  # PATCH /bookmark_collections/:id/add_bookmark
  def add_bookmark
    @collection = current_user.bookmark_collections.find(params[:id])
    bookmark = current_user.bookmarks.find(params[:bookmark_id])
    bookmark.update!(bookmark_collection: @collection)
    render json: { success: true }
  end

  private

  def set_collection
    @collection = current_user.bookmark_collections.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Collection not found' }, status: :not_found
  end

  def collection_params
    params.require(:bookmark_collection).permit(:name, :description)
  end

  def collection_summary(col)
    { id: col.id, name: col.name, description: col.description,
      count: col.bookmarks_count, default: col.is_default }
  end

  def collection_json(col)
    {
      id:          col.id,
      name:        col.name,
      description: col.description,
      bookmarks:   @bookmarks.map { |b| bookmark_item_json(b) },
      next_page:   @bookmarks.next_page
    }
  end

  def bookmark_item_json(b)
    { id: b.id, type: b.bookmarkable_type, item_id: b.bookmarkable_id }
  end
end
