require 'rails_helper'

RSpec.describe AiMarketplaceValuationService do
  let(:user) { User.create!(name: 'Seller User', email: "seller_#{SecureRandom.hex(4)}@test.com", password: 'password123') }
  let(:listing) do
    MarketplaceListing.create!(
      user: user,
      title: 'iPhone 13 Pro 128GB',
      category: 'electronics',
      condition: 'like_new',
      price: 500.0,
      status: 'active'
    )
  end

  describe '#estimate_price' do
    it 'returns price valuation range and suggested price' do
      service = AiMarketplaceValuationService.new(
        title: listing.title,
        category: listing.category,
        condition: listing.condition,
        price: listing.price
      )
      result = service.estimate_price

      expect(result[:success]).to be true
      expect(result[:suggested_price]).to be > 0
      expect(result[:min_price]).to be <= result[:suggested_price]
      expect(result[:max_price]).to be >= result[:suggested_price]
    end
  end

  describe '.negotiate_offer' do
    it 'accepts fair offers within 20% discount' do
      result = AiMarketplaceValuationService.negotiate_offer(listing, 450.0)
      expect(result[:status]).to eq('accepted')
    end

    it 'counters mid-range offers' do
      result = AiMarketplaceValuationService.negotiate_offer(listing, 350.0)
      expect(result[:status]).to eq('countered')
      expect(result[:counter_price]).to be_present
    end

    it 'declines extreme low-ball offers' do
      result = AiMarketplaceValuationService.negotiate_offer(listing, 100.0)
      expect(result[:status]).to eq('declined')
    end
  end
end
