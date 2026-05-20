require 'rails_helper'

RSpec.describe "User Authentication", type: :system do
  let(:user) { create(:user) }
  
  describe "Login flow" do
    before { visit new_user_session_path }
    
    it "displays login page correctly" do
      expect(page).to have_css('h1.auth-logo', text: 'Sangam')
      expect(page).to have_css('p.auth-subtitle', text: 'Connect with friends')
      expect(page).to have_field('Email address')
      expect(page).to have_field('Password')
      expect(page).to have_button('Log In')
    end
    
    it "has animated elements" do
      expect(page).to have_css('div.auth-card')
      expect(page).to have_css('h1.auth-logo')
    end
    
    it "has remember me checkbox" do
      expect(page).to have_field('Keep me logged in')
    end
    
    it "has forgot password link" do
      expect(page).to have_link('Forgot Password?')
    end
    
    it "has signup link" do
      expect(page).to have_link('Sign Up')
    end
    
    context "with valid credentials" do
      it "logs in successfully" do
        fill_in 'Email address', with: user.email
        fill_in 'Password', with: 'password123'
        click_button 'Log In'
        
        expect(page).to have_css('header.dashboard-header')
        expect(page).to have_content('Welcome')
      end
      
      it "redirects to dashboard" do
        fill_in 'Email address', with: user.email
        fill_in 'Password', with: 'password123'
        click_button 'Log In'
        
        expect(current_path).to eq(root_path)
        expect(page).to have_css('div.dashboard-container')
      end
    end
    
    context "with invalid credentials" do
      it "shows error message with wrong password" do
        fill_in 'Email address', with: user.email
        fill_in 'Password', with: 'wrongpassword'
        click_button 'Log In'
        
        expect(page).to have_css('div.error-messages')
        expect(current_path).to eq(user_session_path)
      end
      
      it "shows error message with wrong email" do
        fill_in 'Email address', with: 'wrong@example.com'
        fill_in 'Password', with: 'password123'
        click_button 'Log In'
        
        expect(page).to have_css('div.error-messages')
      end
    end
    
    it "navigates to signup page" do
      click_link 'Sign Up'
      expect(current_path).to eq(new_user_registration_path)
      expect(page).to have_content('Create a new account')
    end
    
    it "navigates to forgot password page" do
      click_link 'Forgot Password?'
      expect(current_path).to eq(new_user_password_path)
      expect(page).to have_content('Find Your Account')
    end
  end
  
  describe "Signup flow" do
    before { visit new_user_registration_path }
    
    it "displays signup page correctly" do
      expect(page).to have_css('h1.auth-logo', text: 'Sangam')
      expect(page).to have_css('p.auth-subtitle', text: 'Create a new account')
      expect(page).to have_field('Email address')
      expect(page).to have_field('New password')
      expect(page).to have_field('Confirm password')
      expect(page).to have_button('Sign Up')
    end
    
    it "displays terms and policy message" do
      expect(page).to have_content('Terms')
      expect(page).to have_content('Data Policy')
    end
    
    it "has login link" do
      expect(page).to have_link('Already have an account? Log In')
    end
    
    context "with valid data" do
      it "creates new account successfully" do
        email = Faker::Internet.email
        
        fill_in 'Email address', with: email
        fill_in 'New password', with: 'password123'
        fill_in 'Confirm password', with: 'password123'
        
        expect {
          click_button 'Sign Up'
        }.to change(User, :count).by(1)
        
        expect(page).to have_css('header.dashboard-header')
        expect(page).to have_content('Welcome')
      end
    end
    
    context "with invalid data" do
      it "shows error with invalid email" do
        fill_in 'Email address', with: 'invalid-email'
        fill_in 'New password', with: 'password123'
        fill_in 'Confirm password', with: 'password123'
        click_button 'Sign Up'
        
        expect(page).to have_css('div.error-messages')
      end
      
      it "shows error with mismatched passwords" do
        fill_in 'Email address', with: Faker::Internet.email
        fill_in 'New password', with: 'password123'
        fill_in 'Confirm password', with: 'different123'
        click_button 'Sign Up'
        
        expect(page).to have_css('div.error-messages')
      end
      
      it "shows error with short password" do
        fill_in 'Email address', with: Faker::Internet.email
        fill_in 'New password', with: '12345'
        fill_in 'Confirm password', with: '12345'
        click_button 'Sign Up'
        
        expect(page).to have_css('div.error-messages')
      end
    end
    
    it "navigates to login page" do
      click_link 'Already have an account? Log In'
      expect(current_path).to eq(new_user_session_path)
    end
  end
  
  describe "Password reset flow" do
    before { visit new_user_password_path }
    
    it "displays forgot password page correctly" do
      expect(page).to have_css('h1.auth-logo', text: 'Sangam')
      expect(page).to have_css('h2.auth-title', text: 'Find Your Account')
      expect(page).to have_field('Email address')
      expect(page).to have_button('Search')
      expect(page).to have_link('Cancel')
    end
    
    it "sends reset instructions with valid email" do
      fill_in 'Email address', with: user.email
      
      expect {
        click_button 'Search'
      }.to change { ActionMailer::Base.deliveries.count }.by(1)
      
      expect(current_path).to eq(new_user_session_path)
    end
    
    it "cancels and returns to login" do
      click_link 'Cancel'
      expect(current_path).to eq(new_user_session_path)
    end
  end
  
  describe "Dashboard" do
    before do
      sign_in user
      visit root_path
    end
    
    it "displays dashboard correctly" do
      expect(page).to have_css('header.dashboard-header')
      expect(page).to have_css('div.dashboard-container')
      expect(page).to have_content('Welcome')
    end
    
    it "displays user information" do
      expect(page).to have_content(user.email[0].upcase)
    end
    
    it "has search functionality" do
      expect(page).to have_field('Search Sangam')
    end
    
    it "has notification icon" do
      expect(page).to have_css('button[title="Notifications"]')
    end
    
    it "has profile dropdown" do
      expect(page).to have_css('button.profile-button')
      expect(page).to have_css('div.dropdown-menu')
    end
    
    describe "Profile dropdown" do
      it "opens on click" do
        find('button.profile-button').click
        expect(page).to have_css('div.dropdown-menu.active')
      end
      
      it "displays user information" do
        find('button.profile-button').click
        expect(page).to have_content(user.email)
      end
      
      it "has logout button" do
        find('button.profile-button').click
        expect(page).to have_button('Log Out')
      end
      
      it "logs out user" do
        find('button.profile-button').click
        click_button 'Log Out'
        
        expect(current_path).to eq(root_path)
        expect(page).to have_link('Sign In')
      end
    end
    
    it "has sidebar navigation" do
      expect(page).to have_css('aside.dashboard-sidebar')
      expect(page).to have_css('nav.sidebar-menu')
    end
    
    it "has welcome card" do
      expect(page).to have_css('div.welcome-card')
    end
    
    it "has widgets section" do
      expect(page).to have_css('aside.dashboard-widgets')
    end
  end
  
  describe "Responsive design", js: true do
    it "works on mobile viewport" do
      page.driver.browser.manage.window.resize_to(375, 667)
      visit new_user_session_path
      
      expect(page).to have_css('div.auth-container')
      expect(page).to have_css('div.auth-card')
    end
    
    it "dashboard adapts to mobile" do
      sign_in user
      page.driver.browser.manage.window.resize_to(375, 667)
      visit root_path
      
      expect(page).to have_css('header.dashboard-header')
    end
  end
end
