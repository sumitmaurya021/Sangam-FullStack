require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
  end
  
  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
    
    it 'creates a user with faker data' do
      user = create(:user)
      expect(user.email).to be_present
      expect(user.email).to include('@')
    end
    
    it 'creates a user with name trait' do
      user = create(:user, :with_name)
      expect(user.email).to match(/\w+\.\w+@example\.com/)
    end
  end
  
  describe 'devise modules' do
    it 'includes database_authenticatable' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end
    
    it 'includes registerable' do
      expect(User.devise_modules).to include(:registerable)
    end
    
    it 'includes recoverable' do
      expect(User.devise_modules).to include(:recoverable)
    end
    
    it 'includes rememberable' do
      expect(User.devise_modules).to include(:rememberable)
    end
    
    it 'includes validatable' do
      expect(User.devise_modules).to include(:validatable)
    end
  end
  
  describe 'password encryption' do
    it 'encrypts password on save' do
      user = create(:user, password: 'testpassword123', password_confirmation: 'testpassword123')
      expect(user.encrypted_password).to be_present
      expect(user.encrypted_password).not_to eq('testpassword123')
    end
  end
  
  describe 'email uniqueness' do
    it 'does not allow duplicate emails' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'test@example.com')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
    
    it 'is case insensitive' do
      create(:user, email: 'Test@Example.com')
      duplicate_user = build(:user, email: 'test@example.com')
      expect(duplicate_user).not_to be_valid
    end
  end
end
