require 'rails_helper'

RSpec.describe Poll, type: :model do
  let(:author) { create(:user) }
  let(:voter)  { create(:user) }
  let(:post_record) do
    Post.create!(user: author, content: 'Vote!', visibility: 'public')
  end

  def build_poll(attrs = {})
    poll = Poll.new({ post: post_record, question: 'Best colour?' }.merge(attrs))
    poll.poll_options.build(body: 'Red',  position: 0)
    poll.poll_options.build(body: 'Blue', position: 1)
    poll
  end

  # ── Associations ────────────────────────────────────────────────────────────
  it { is_expected.to belong_to(:post) }
  it { is_expected.to have_many(:poll_options).dependent(:destroy) }
  it { is_expected.to have_many(:poll_votes).dependent(:destroy) }

  # ── Validations ─────────────────────────────────────────────────────────────
  describe 'validations' do
    it 'is valid with question and 2+ options' do
      expect(build_poll).to be_valid
    end

    it 'requires a question' do
      poll = build_poll(question: '')
      expect(poll).not_to be_valid
      expect(poll.errors[:question]).to be_present
    end

    it 'requires at least 2 options' do
      poll = Poll.new(post: post_record, question: 'Q?')
      poll.poll_options.build(body: 'Only one', position: 0)
      expect(poll).not_to be_valid
    end

    it 'rejects ends_at in the past' do
      poll = build_poll(ends_at: 1.hour.ago)
      expect(poll).not_to be_valid
      expect(poll.errors[:ends_at]).to be_present
    end

    it 'accepts ends_at in the future' do
      poll = build_poll(ends_at: 2.days.from_now)
      expect(poll).to be_valid
    end
  end

  # ── total_votes ──────────────────────────────────────────────────────────────
  describe '#total_votes' do
    it 'starts at 0' do
      poll = build_poll
      poll.save!
      expect(poll.total_votes).to eq 0
    end
  end

  # ── active? ──────────────────────────────────────────────────────────────────
  describe '#active?' do
    it 'returns true when not expired and no end date' do
      poll = build_poll
      poll.save!
      expect(poll.active?).to be true
    end

    it 'returns false when manually expired' do
      poll = build_poll
      poll.save!
      poll.expire!
      expect(poll.active?).to be false
    end

    it 'returns false when ends_at is in the past' do
      poll = build_poll
      poll.save!
      poll.update_columns(ends_at: 1.hour.ago)
      expect(poll.active?).to be false
    end
  end

  # ── voted_by? / vote_for! / user_choice ─────────────────────────────────────
  describe 'voting' do
    let!(:poll)   { poll = build_poll; poll.save!; poll }
    let(:option)  { poll.poll_options.first }

    it '#voted_by? returns false before voting' do
      expect(poll.voted_by?(voter)).to be false
    end

    it '#vote_for! records the vote' do
      expect { poll.vote_for!(voter, option) }.to change { PollVote.count }.by(1)
    end

    it '#vote_for! increments votes_count on the option' do
      expect { poll.vote_for!(voter, option) }
        .to change { option.reload.votes_count }.by(1)
    end

    it '#voted_by? returns true after voting' do
      poll.vote_for!(voter, option)
      expect(poll.voted_by?(voter)).to be true
    end

    it '#vote_for! returns false when already voted' do
      poll.vote_for!(voter, option)
      expect(poll.vote_for!(voter, option)).to be false
    end

    it '#vote_for! returns false when poll is expired' do
      poll.expire!
      expect(poll.vote_for!(voter, option)).to be false
    end

    it '#user_choice returns the option the user voted for' do
      poll.vote_for!(voter, option)
      expect(poll.user_choice(voter)).to eq option
    end

    it '#user_choice returns nil for non-voter' do
      expect(poll.user_choice(voter)).to be_nil
    end
  end

  # ── expire! ──────────────────────────────────────────────────────────────────
  describe '#expire!' do
    it 'sets expired to true' do
      poll = build_poll; poll.save!
      poll.expire!
      expect(poll.reload.expired).to be true
    end
  end
end

RSpec.describe PollOption, type: :model do
  let(:author)      { create(:user) }
  let(:post_record) { Post.create!(user: author, content: 'Q', visibility: 'public') }

  def make_poll
    poll = Poll.new(post: post_record, question: 'Q?')
    poll.poll_options.build(body: 'A', position: 0)
    poll.poll_options.build(body: 'B', position: 1)
    poll.save!
    poll
  end

  it { is_expected.to belong_to(:poll) }
  it { is_expected.to have_many(:poll_votes).dependent(:destroy) }

  describe '#percentage' do
    it 'returns 0 when there are no votes' do
      option = make_poll.poll_options.first
      expect(option.percentage).to eq 0
    end

    it 'calculates correct percentage after votes' do
      poll   = make_poll
      opt_a  = poll.poll_options.first
      voter1 = create(:user)
      voter2 = create(:user)
      poll.vote_for!(voter1, opt_a)
      poll.vote_for!(voter2, opt_a)
      # 2 out of 2 votes on opt_a = 100%
      expect(opt_a.reload.percentage).to eq 100.0
    end
  end
end

RSpec.describe PollVote, type: :model do
  it { is_expected.to belong_to(:poll) }
  it { is_expected.to belong_to(:poll_option) }
  it { is_expected.to belong_to(:user) }

  it 'enforces one vote per user per poll' do
    author = create(:user)
    voter  = create(:user)
    post_r = Post.create!(user: author, content: 'Q', visibility: 'public')
    poll   = Poll.new(post: post_r, question: 'Q?')
    poll.poll_options.build(body: 'A', position: 0)
    poll.poll_options.build(body: 'B', position: 1)
    poll.save!

    option = poll.poll_options.first
    poll.vote_for!(voter, option)
    expect(poll.vote_for!(voter, option)).to be false
  end
end
