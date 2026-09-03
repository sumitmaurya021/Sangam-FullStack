require 'rails_helper'

RSpec.describe "MarketplaceListings", type: :request do
  let(:user) { create(:user) }
  let!(:listing) do
    create(:marketplace_listing,
      user: user,
      title: 'Vintage Guitar',
      price: 250.00,
      category: 'electronics',
      condition: 'good',
      status: 'active'
    )
  end

  before { sign_in user }

  describe "GET /marketplace" do
    it "returns http success" do
      get marketplace_listing_index_path
      expect(response).to have_http_status(:success)
    end

    it "filters by category" do
      get marketplace_listing_index_path, params: { category: 'Electronics' }
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /marketplace/:id" do
    it "returns http success and increments view count" do
      expect {
        get marketplace_listing_path(listing)
      }.to change { listing.reload.views_count }.by(1)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /marketplace/new" do
    it "returns http success" do
      get new_marketplace_listing_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /marketplace" do
    it "creates a listing with valid params" do
      expect {
        post marketplace_listing_index_path, params: {
          marketplace_listing: {
            title: 'Old Camera',
            description: 'Works great',
            price: 75.00,
            category: 'electronics',
            condition: 'good'
          }
        }
      }.to change(MarketplaceListing, :count).by(1)
      expect(response).to redirect_to(marketplace_listing_path(MarketplaceListing.last))
    end

    it "rejects invalid params" do
      expect {
        post marketplace_listing_index_path, params: {
          marketplace_listing: { title: '', price: -1 }
        }
      }.not_to change(MarketplaceListing, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /marketplace/:id" do
    it "updates listing when owner" do
      patch marketplace_listing_path(listing), params: {
        marketplace_listing: { title: 'Acoustic Guitar Updated' }
      }
      expect(response).to redirect_to(marketplace_listing_path(listing))
      expect(listing.reload.title).to eq('Acoustic Guitar Updated')
    end

    it "prevents non-owner from updating" do
      other_user = create(:user)
      sign_in other_user
      patch marketplace_listing_path(listing), params: {
        marketplace_listing: { title: 'Hacked' }
      }
      expect(response).to redirect_to(marketplace_listing_index_path)
      expect(listing.reload.title).not_to eq('Hacked')
    end
  end

  describe "DELETE /marketplace/:id" do
    it "deletes the listing when owner" do
      expect {
        delete marketplace_listing_path(listing)
      }.to change(MarketplaceListing, :count).by(-1)
      expect(response).to redirect_to(marketplace_listing_index_path)
    end
  end

  describe "PATCH /marketplace/:id/mark_sold" do
    it "marks listing as sold" do
      patch mark_sold_marketplace_listing_path(listing), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe "GET /marketplace/my_listings" do
    it "returns user's listings" do
      get my_listings_marketplace_listing_index_path
      expect(response).to have_http_status(:success)
    end
  end
end
