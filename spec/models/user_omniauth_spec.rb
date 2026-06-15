require 'rails_helper'

RSpec.describe User, type: :model do
  # Helper: build a mock OmniAuth auth hash
  def omniauth_hash(provider:, uid:, email:, name:)
    OmniAuth::AuthHash.new(
      provider: provider.to_s,
      uid:      uid.to_s,
      info: OmniAuth::AuthHash::InfoHash.new(
        email:    email,
        name:     name,
        nickname: nil
      )
    )
  end

  describe '.from_omniauth' do
    let(:auth_google) do
      omniauth_hash(provider: 'google_oauth2', uid: 'google-123',
                    email: 'alice@gmail.com', name: 'Alice Example')
    end

    let(:auth_github) do
      omniauth_hash(provider: 'github', uid: 'gh-456',
                    email: 'bob@github.com', name: 'Bob Dev')
    end

    context 'brand-new OAuth user (no existing account)' do
      it 'creates a new user for Google' do
        expect { User.from_omniauth(auth_google) }.to change(User, :count).by(1)
      end

      it 'stores provider and uid' do
        user = User.from_omniauth(auth_google)
        expect(user.provider).to eq 'google_oauth2'
        expect(user.uid).to eq 'google-123'
      end

      it 'sets confirmed_at (skips email confirmation)' do
        user = User.from_omniauth(auth_google)
        expect(user.confirmed_at).not_to be_nil
      end

      it 'creates a GitHub user too' do
        user = User.from_omniauth(auth_github)
        expect(user).to be_persisted
        expect(user.provider).to eq 'github'
      end
    end

    context 'existing OAuth user (same provider + uid)' do
      it 'returns the existing user without creating a new one' do
        existing = User.from_omniauth(auth_google)
        expect { User.from_omniauth(auth_google) }.not_to change(User, :count)
        returned = User.from_omniauth(auth_google)
        expect(returned.id).to eq existing.id
      end
    end

    context 'user with same email already exists (email-based link)' do
      let!(:existing_user) { create(:user, email: 'alice@gmail.com') }

      it 'does not create a new user' do
        expect { User.from_omniauth(auth_google) }.not_to change(User, :count)
      end

      it 'links provider and uid to the existing account' do
        user = User.from_omniauth(auth_google)
        expect(user.id).to eq existing_user.id
        expect(user.reload.provider).to eq 'google_oauth2'
        expect(user.reload.uid).to eq 'google-123'
      end
    end

    context 'different providers for same email' do
      let!(:google_user) { User.from_omniauth(auth_google) }

      it 'links github to the same account if email matches' do
        github_auth = omniauth_hash(provider: 'github', uid: 'gh-999',
                                    email: 'alice@gmail.com', name: 'Alice')
        user = User.from_omniauth(github_auth)
        expect(user.id).to eq google_user.id
      end
    end
  end
end
