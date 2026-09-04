require 'rails_helper'

RSpec.describe "Groups", type: :request do
  let(:user)  { create(:user) }
  let!(:group) { create(:group, owner: user, privacy: 'public') }

  before { sign_in user }

  describe "GET /groups" do
    it "returns http success" do
      get groups_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /groups/:id" do
    it "returns http success" do
      get group_path(group)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /groups/new" do
    it "returns http success" do
      get new_group_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /groups" do
    it "creates a group with valid params" do
      expect {
        post groups_path, params: {
          group: { name: 'New Test Group', description: 'A test group', privacy: 'public' }
        }
      }.to change(Group, :count).by(1)
      expect(response).to redirect_to(group_path(Group.last))
    end

    it "does not create group with invalid params" do
      expect {
        post groups_path, params: { group: { name: '', description: '' } }
      }.not_to change(Group, :count)
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /groups/:id" do
    it "deletes the group when admin" do
      expect {
        delete group_path(group)
      }.to change(Group, :count).by(-1)
      expect(response).to redirect_to(groups_path)
    end
  end

  describe "POST /groups/:id/join" do
    it "joins a public group" do
      other_user = create(:user)
      sign_in other_user
      post join_group_path(group), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['joined']).to be true
    end
  end

  describe "DELETE /groups/:id/leave" do
    it "allows a member to leave" do
      other_user = create(:user)
      create(:group_membership, user: other_user, group: group, role: 'member', status: 'active')
      sign_in other_user
      delete leave_group_path(group), as: :json
      expect(response).to have_http_status(:success)
    end
  end
end
