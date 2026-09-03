require 'rails_helper'

RSpec.describe "BookmarkCollections", type: :request do
  let(:user) { create(:user) }
  let!(:collection) { create(:bookmark_collection, user: user, name: 'My Bookmarks') }

  before { sign_in user }

  describe "GET /bookmark_collections" do
    it "returns http success" do
      get bookmark_collections_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON list of collections" do
      get bookmark_collections_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
    end
  end

  describe "GET /bookmark_collections/:id" do
    it "returns http success" do
      get bookmark_collection_path(collection)
      expect(response).to have_http_status(:success)
    end

    it "returns JSON with bookmarks" do
      get bookmark_collection_path(collection), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('bookmarks')
    end
  end

  describe "POST /bookmark_collections" do
    it "creates a new collection" do
      expect {
        post bookmark_collections_path,
          params: { bookmark_collection: { name: 'Tech Reads', description: 'My tech bookmarks' } },
          as: :json
      }.to change(BookmarkCollection, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "rejects invalid params" do
      expect {
        post bookmark_collections_path,
          params: { bookmark_collection: { name: '' } },
          as: :json
      }.not_to change(BookmarkCollection, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "PATCH /bookmark_collections/:id" do
    it "updates collection name" do
      patch bookmark_collection_path(collection),
        params: { bookmark_collection: { name: 'Updated Name' } },
        as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
      expect(collection.reload.name).to eq('Updated Name')
    end
  end

  describe "DELETE /bookmark_collections/:id" do
    context "when collection is not default" do
      it "deletes the collection" do
        non_default = create(:bookmark_collection, user: user, name: 'To Delete')
        expect {
          delete bookmark_collection_path(non_default), as: :json
        }.to change(BookmarkCollection, :count).by(-1)
        json = JSON.parse(response.body)
        expect(json['success']).to be true
      end
    end

    context "when collection is default" do
      it "refuses to delete and returns error" do
        collection.update_column(:is_default, true)
        expect {
          delete bookmark_collection_path(collection), as: :json
        }.not_to change(BookmarkCollection, :count)
        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
