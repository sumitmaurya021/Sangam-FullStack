require 'rails_helper'

RSpec.describe "Polls", type: :request do
  let(:user) { create(:user) }
  let(:post_record) { create(:post, user: user) }
  let!(:poll) { create(:poll, post: post_record, ends_at: 1.day.from_now) }
  let(:poll_option) { poll.poll_options.first }

  before { sign_in user }

  describe "POST /polls/:id/vote" do
    it "records a vote for a valid option" do
      post vote_poll_path(poll), params: { poll_option_id: poll_option.id }, as: :json
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      expect(json['success']).to be true
    end

    it "returns error when already voted" do
      poll.vote_for!(user, poll_option)
      post vote_poll_path(poll), params: { poll_option_id: poll_option.id }, as: :json
      json = JSON.parse(response.body)
      expect(json['error']).to match(/already voted/i)
    end

    it "returns error when poll has expired" do
      poll.update_columns(expired: true)
      post vote_poll_path(poll), params: { poll_option_id: poll_option.id }, as: :json
      json = JSON.parse(response.body)
      expect(json['error']).to match(/ended/i)
    end

    it "returns error for invalid option" do
      post vote_poll_path(poll), params: { poll_option_id: 999_999 }, as: :json
      json = JSON.parse(response.body)
      expect(json['error']).to match(/invalid option/i)
    end
  end
end
