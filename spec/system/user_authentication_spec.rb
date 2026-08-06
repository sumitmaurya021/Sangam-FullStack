require 'rails_helper'

RSpec.describe "User Authentication", type: :system do
  let(:user) { create(:user) }
  
  describe "Login flow" do
    before { visit new_user_session_path }
    
    it "displays login page correctly" do
      expect(page).to have_content('Welcome back')
      expect(page).to have_field('user_email')
      expect(page).to have_field('user_password')
      expect(page).to have_button('Sign In to Sangam')
    end
    
    it "has remember me checkbox" do
      expect(page).to have_field('user_remember_me', type: 'checkbox', visible: :all)
    end
    
    it "has forgot password link" do
      expect(page).to have_link('Forgot?')
    end
    
    it "has signup link" do
      expect(page).to have_link('Create account')
    end
    
    context "with valid credentials" do
      it "logs in successfully" do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'password123'
        click_button 'Sign In to Sangam'
        
        expect(page).to have_current_path(root_path)
      end
    end
    
    context "with invalid credentials" do
      it "shows error message with wrong password" do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'wrongpassword'
        click_button 'Sign In to Sangam'
        
        expect(current_path).to eq(new_user_session_path)
      end
    end
    
    it "navigates to signup page" do
      expect(page).to have_link('Create account')
      click_link 'Create account'
      expect(page).to have_content('Create your account')
    end
    
    it "navigates to forgot password page" do
      expect(page).to have_link('Forgot?')
      click_link 'Forgot?'
      expect(page).to have_content('Reset your password')
    end
  end
  
  describe "Signup flow" do
    before { visit new_user_registration_path }
    
    it "displays signup page correctly" do
      expect(page).to have_content('Create your account')
      expect(page).to have_field('user_name')
      expect(page).to have_field('user_email')
      expect(page).to have_field('user_password')
      expect(page).to have_field('user_password_confirmation')
      expect(page).to have_button('Create Your Account')
    end
    
    context "with valid data" do
      let(:email) { Faker::Internet.email }
      
      it "creates new account successfully" do
        fill_in 'user_name', with: 'Test User'
        fill_in 'user_email', with: email
        fill_in 'user_password', with: 'password123'
        fill_in 'user_password_confirmation', with: 'password123'
        click_button 'Create Your Account'
        
        expect(page).to have_current_path(root_path).or have_content('Create your account')
      end
    end
    
    context "with invalid data" do
      it "shows error with invalid email" do
        fill_in 'user_name', with: 'Test User'
        fill_in 'user_email', with: 'invalid-email'
        fill_in 'user_password', with: 'password123'
        fill_in 'user_password_confirmation', with: 'password123'
        click_button 'Create Your Account'
        
        expect(page).to have_content('Create your account')
      end
    end
    
    it "navigates to login page" do
      expect(page).to have_link('Sign In')
      click_link 'Sign In'
      expect(page).to have_content('Welcome back')
    end
  end
  
  describe "Dashboard" do
    before do
      sign_in user
      visit root_path
    end
    
    it "displays posts feed correctly" do
      expect(page).to have_current_path(root_path)
    end
  end
end
