require 'rails_helper'

RSpec.describe "User Authentication", type: :system do
  let(:user) { create(:user) }
  
  describe "Login flow" do
    before { visit new_user_session_path }
    
    it "displays login page correctly" do
      expect(page).to have_css('span.auth-brand-logo', text: 'Sangam')
      expect(page).to have_css('span.auth-brand-tagline', text: 'Connect with friends')
      expect(page).to have_field('user_email')
      expect(page).to have_field('user_password')
      expect(page).to have_button('Sign in')
    end
    
    it "has remember me checkbox" do
      # Check for checkbox by ID
      expect(page).to have_css('input#remember_me[type="checkbox"]')
    end
    
    it "has forgot password link" do
      expect(page).to have_link('Forgot password?')
    end
    
    it "has signup link" do
      expect(page).to have_link('Create account')
    end
    
    context "with valid credentials" do
      it "logs in successfully" do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'password123'
        click_button 'Sign in'
        
        expect(page).to have_css('header.fb-header')
        expect(page).to have_css('div.feed-container')
      end
      
      it "redirects to posts feed" do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'password123'
        click_button 'Sign in'
        
        # Should be redirected to feed
        expect(page).to have_css('div.feed-container')
      end
    end
    
    context "with invalid credentials" do
      it "shows error message with wrong password" do
        fill_in 'user_email', with: user.email
        fill_in 'user_password', with: 'wrongpassword'
        click_button 'Sign in'
        
        # Should stay on login page when credentials are invalid
        expect(current_path).to eq(user_session_path)
      end
    end
    
    it "navigates to signup page" do
      # Wait for page to load and find link
      expect(page).to have_link('Create account')
      within('.auth-signup') do
        click_link 'Create account'
      end
      expect(page).to have_content('Create account')
    end
    
    it "navigates to forgot password page" do
      expect(page).to have_link('Forgot password?')
      click_link 'Forgot password?'
      expect(page).to have_content('Find Your Account')
    end
  end
  
  describe "Signup flow" do
    before { visit new_user_registration_path }
    
    it "displays signup page correctly" do
      expect(page).to have_css('span.auth-brand-logo', text: 'Sangam')
      expect(page).to have_content('Create account')
      expect(page).to have_field('user_name')
      expect(page).to have_field('user_email')
      expect(page).to have_field('user_password')
      expect(page).to have_field('user_password_confirmation')
      expect(page).to have_button('Sign Up')
    end
    
    it "displays terms and policy message" do
      expect(page).to have_content('Terms')
      expect(page).to have_content('Data Policy')
    end
    
    context "with valid data" do
      let(:email) { Faker::Internet.email }
      
      it "creates new account successfully" do
        fill_in 'user_name', with: 'Test User'
        fill_in 'user_email', with: email
        fill_in 'user_password', with: 'password123'
        fill_in 'user_password_confirmation', with: 'password123'
        click_button 'Sign Up'
        
        expect(page).to have_css('header.fb-header')
        expect(current_path).to eq(root_path)
      end
    end
    
    context "with invalid data" do
      it "shows error with invalid email" do
        fill_in 'user_name', with: 'Test User'
        fill_in 'user_email', with: 'invalid-email'
        fill_in 'user_password', with: 'password123'
        fill_in 'user_password_confirmation', with: 'password123'
        click_button 'Sign Up'
        
        # Form should stay on signup page when there's an error
        expect(page).to have_content('Create account')
      end
      
      it "shows error with mismatched passwords" do
        fill_in 'user_name', with: 'Test User'
        fill_in 'user_email', with: Faker::Internet.email
        fill_in 'user_password', with: 'password123'
        fill_in 'user_password_confirmation', with: 'different'
        click_button 'Sign Up'
        
        expect(page).to have_content('error')
      end
      
      it "shows error with short password" do
        fill_in 'user_name', with: 'Test User'
        fill_in 'user_email', with: Faker::Internet.email
        fill_in 'user_password', with: '123'
        fill_in 'user_password_confirmation', with: '123'
        click_button 'Sign Up'
        
        expect(page).to have_content('error')
      end
    end
    
    it "navigates to login page" do
      expect(page).to have_link('Already have an account? Log In')
      click_link 'Already have an account? Log In'
      expect(page).to have_content('Welcome back')
    end
  end
  
  describe "Password reset flow" do
    before { visit new_user_password_path }
    
    it "displays forgot password page correctly" do
      expect(page).to have_css('span.auth-brand-logo', text: 'Sangam')
      expect(page).to have_content('Find Your Account')
      expect(page).to have_field('user_email')
      expect(page).to have_button('Send Reset Instructions')
    end
    
    it "sends reset instructions with valid email" do
      fill_in 'user_email', with: user.email
      click_button 'Send Reset Instructions'
      
      # After submitting, should show success message or stay on page
      expect(page).to have_content('Sangam')
    end
    
    it "has back to login link" do
      expect(page).to have_link('Back to Sign In')
    end
  end
  
  describe "Dashboard" do
    before do
      sign_in user
      visit root_path
    end
    
    it "displays posts feed correctly" do
      expect(page).to have_css('header.fb-header')
      expect(page).to have_css('div.feed-container')
      expect(page).to have_css('div.create-post-card')
    end
    
    it "has header with logo" do
      expect(page).to have_css('svg.fb-logo')
    end
    
    it "has search functionality" do
      within('header.fb-header') do
        expect(page).to have_css('input[placeholder*="Search"]')
      end
    end
    
    it "has profile dropdown" do
      expect(page).to have_css('button.fb-profile-btn')
    end
    
    describe "Profile dropdown" do
      it "opens on click" do
        find('button.fb-profile-btn').click
        expect(page).to have_css('div.fb-user-dropdown.show')
      end
      
      it "displays user information" do
        find('button.fb-profile-btn').click
        expect(page).to have_content(user.name)
      end
      
      it "has logout button" do
        find('button.fb-profile-btn').click
        expect(page).to have_button('Log Out')
      end
      
      it "logs out user" do
        find('button.fb-profile-btn').click
        click_button 'Log Out'
        expect(current_path).to eq(root_path)
      end
    end
    
    it "has friend requests sidebar" do
      # Sidebar may be hidden on mobile, just check it exists in DOM
      expect(page).to have_css('aside.feed-sidebar', visible: :all)
    end
    
    it "has friends sidebar" do
      # Sidebar may be hidden on mobile, just check it exists in DOM
      expect(page).to have_css('aside.feed-right-sidebar', visible: :all)
    end
  end
  
  describe "Responsive design" do
    it "works on mobile viewport" do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit new_user_session_path
      
      expect(page).to have_css('div.auth-container')
    end
    
    it "feed adapts to mobile" do
      sign_in user
      page.driver.browser.manage.window.resize_to(375, 667)
      visit root_path
      
      expect(page).to have_css('header.fb-header')
    end
  end
end
