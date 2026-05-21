require 'rails_helper'

RSpec.describe "Users::Passwords", type: :request do
  let(:user) { create(:user) }
  
  describe "GET /users/password/new" do
    it "returns http success" do
      get new_user_password_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays the forgot password page" do
      get new_user_password_path
      expect(response.body).to include('Sangam')
      expect(response.body).to include('Find Your Account')
    end
    
    it "includes CSS stylesheet link" do
      get new_user_password_path
      expect(response.body).to include('users/passwords')
    end
    
    it "has email field" do
      get new_user_password_path
      expect(response.body).to include('Email Address')
    end
    
    it "has send reset button" do
      get new_user_password_path
      expect(response.body).to include('Send Reset Instructions')
    end
    
    it "has back to login link" do
      get new_user_password_path
      expect(response.body).to include('Back to Sign In')
    end
  end
  
  describe "POST /users/password" do
    context "with valid email" do
      it "sends password reset instructions" do
        expect {
          post user_password_path, params: {
            user: { email: user.email }
          }
        }.to change { ActionMailer::Base.deliveries.count }.by(1)
      end
      
      it "redirects to login page" do
        post user_password_path, params: {
          user: { email: user.email }
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
    
    context "with invalid email" do
      it "does not send email" do
        expect {
          post user_password_path, params: {
            user: { email: 'nonexistent@example.com' }
          }
        }.not_to change { ActionMailer::Base.deliveries.count }
      end
      
      it "displays error message" do
        post user_password_path, params: {
          user: { email: 'nonexistent@example.com' }
        }
        expect(response.body).to include('error')
      end
    end
  end
  
  describe "GET /users/password/edit" do
    let(:reset_token) { user.send_reset_password_instructions }
    
    it "returns http success with valid token" do
      get edit_user_password_path(reset_password_token: reset_token)
      expect(response).to have_http_status(:success)
    end
    
    it "displays the change password page" do
      get edit_user_password_path(reset_password_token: reset_token)
      expect(response.body).to include('Change Password')
    end
    
    it "has password fields" do
      get edit_user_password_path(reset_password_token: reset_token)
      expect(response.body).to include('New Password')
      expect(response.body).to include('Confirm New Password')
    end
    
    it "has change password button" do
      get edit_user_password_path(reset_password_token: reset_token)
      expect(response.body).to include('Change Password')
    end
  end
  
  describe "PUT /users/password" do
    context "with valid parameters" do
      it "updates the password" do
        # Generate reset token properly
        raw_token = user.send_reset_password_instructions
        
        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }
        expect(response).to redirect_to(root_path)
      end
      
      it "allows login with new password" do
        # Generate reset token properly
        raw_token = user.send_reset_password_instructions
        
        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: 'newpassword123',
            password_confirmation: 'newpassword123'
          }
        }
        
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'newpassword123'
          }
        }
        expect(response).to redirect_to(root_path)
      end
    end
    
    context "with mismatched passwords" do
      it "does not update the password" do
        raw_token = user.send_reset_password_instructions
        
        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: 'newpassword123',
            password_confirmation: 'different123'
          }
        }
        expect(response.body).to include('error')
      end
    end
    
    context "with short password" do
      it "does not update the password" do
        raw_token = user.send_reset_password_instructions
        
        put user_password_path, params: {
          user: {
            reset_password_token: raw_token,
            password: '12345',
            password_confirmation: '12345'
          }
        }
        expect(response.body).to include('error')
      end
    end
  end
end
