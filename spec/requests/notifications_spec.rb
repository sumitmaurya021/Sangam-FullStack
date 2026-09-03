require 'rails_helper'

RSpec.describe "Notifications", type: :request do
  let(:user) { create(:user) }
  let(:actor) { create(:user) }
  let!(:notification) do
    create(:notification, recipient: user, actor: actor, notification_type: 'like')
  end

  before { sign_in user }

  describe "GET /notifications" do
    it "returns http success" do
      get notifications_path
      expect(response).to have_http_status(:success)
    end

    it "returns JSON with notifications" do
      get notifications_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['notifications']).to be_an(Array)
      expect(json['unread_count']).to be_a(Integer)
    end
  end

  describe "GET /notifications/dropdown" do
    it "returns JSON dropdown data" do
      get dropdown_notifications_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json).to have_key('notifications')
      expect(json).to have_key('unread_count')
    end
  end

  describe "PATCH /notifications/:id/mark_read" do
    it "marks notification as read" do
      patch mark_read_notification_path(notification), as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end

  describe "PATCH /notifications/mark_all_read" do
    it "marks all notifications as read" do
      patch mark_all_read_notifications_path, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['unread_count']).to eq(0)
    end
  end

  describe "DELETE /notifications/:id" do
    it "deletes a notification" do
      expect {
        delete notification_path(notification), as: :json
      }.to change(Notification, :count).by(-1)

      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end
  end
end
