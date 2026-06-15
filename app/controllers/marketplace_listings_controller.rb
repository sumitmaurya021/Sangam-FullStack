class MarketplaceListingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_listing, only: [:show, :edit, :update, :destroy, :mark_sold]

  # GET /marketplace
  def index
    @listings = MarketplaceListing.active.recent

    @listings = @listings.by_category(params[:category]) if params[:category].present?
    @listings = @listings.search(params[:q])              if params[:q].present?

    if params[:min_price].present?
      @listings = @listings.where('price >= ?', params[:min_price].to_f)
    end
    if params[:max_price].present?
      @listings = @listings.where('price <= ?', params[:max_price].to_f)
    end

    @listings = @listings.includes(:user).page(params[:page]).per(20)
    @categories = MarketplaceListing::CATEGORIES
  end

  # GET /marketplace/:id
  def show
    @listing.increment!(:views_count)
    @seller = @listing.user
    @related = MarketplaceListing.active
                                 .where(category: @listing.category)
                                 .where.not(id: @listing.id)
                                 .limit(6)
  end

  # GET /marketplace/new
  def new
    @listing = MarketplaceListing.new
  end

  # POST /marketplace
  def create
    @listing = current_user.marketplace_listings.build(listing_params)
    if @listing.save
      respond_to do |format|
        format.html { redirect_to marketplace_listing_path(@listing), notice: 'Listing created!' }
        format.json { render json: { success: true, id: @listing.id }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @listing.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # GET /marketplace/:id/edit
  def edit
    authorize_listing!
  end

  # PATCH /marketplace/:id
  def update
    authorize_listing!
    if @listing.update(listing_params)
      respond_to do |format|
        format.html { redirect_to marketplace_listing_path(@listing), notice: 'Listing updated!' }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @listing.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /marketplace/:id
  def destroy
    authorize_listing!
    @listing.destroy
    respond_to do |format|
      format.html { redirect_to marketplace_listing_index_path, notice: 'Listing deleted.' }
      format.json { render json: { success: true } }
    end
  end

  # PATCH /marketplace/:id/mark_sold
  def mark_sold
    authorize_listing!
    @listing.mark_sold!
    render json: { success: true, status: 'sold' }
  end

  # GET /marketplace/my_listings
  def my_listings
    @listings = current_user.marketplace_listings.recent
                             .page(params[:page]).per(20)
  end

  private

  def set_listing
    @listing = MarketplaceListing.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to marketplace_listing_index_path, alert: 'Listing not found.'
  end

  def authorize_listing!
    redirect_to marketplace_listing_index_path, alert: 'Not authorized.' unless @listing.user == current_user
  end

  def listing_params
    params.require(:marketplace_listing).permit(
      :title, :description, :price, :category, :condition,
      :location_name, :price_negotiable, images: []
    )
  end
end
