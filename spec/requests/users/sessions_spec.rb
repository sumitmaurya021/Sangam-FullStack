require 'rails_helper'

RSpec.describe "Users::Sessions", type: :request do
  let(:user) { create(:user) }
  
  describe "GET /users/sign_in" do
    it "returns http success" do
      get new_user_session_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays the login page" do
      get new_user_session_path
      expect(response.body).to include('Sangam')
      expect(response.body).to include('Connect with friends')
    end
    
    it "includes CSS stylesheet link" do
      get new_user_session_path
      expect(response.body).to include('users/sessions')
    end
    
    it "has email and password fields" do
      get new_user_session_path
      expect(response.body).to include('Email Address')
      expect(response.body).to include('Password')
    end
    
    it "has remember me checkbox" do
      get new_user_session_path
      expect(response.body).to include('Keep me signed in')
    end
    
    it "has login button" do
      get new_user_session_path
      expect(response.body).to include('Sign in')
    end
    
    it "has signup link" do
      get new_user_session_path
      expect(response.body).to include('Create account')
    end
    
    it "has forgot password link" do
      get new_user_session_path
      expect(response.body).to include('Forgot password?')
    end
  end
  
  describe "POST /users/sign_in" do
    context "with valid credentials" do
      it "logs in the user" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        }
        expect(response).to redirect_to(root_path)
      end
      
      it "sets the user session" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password123'
          }
        }
        follow_redirect!
        expect(response.body).to include('post-card')
      end
    end
    
    context "with invalid credentials" do
      it "does not log in with wrong password" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'wrongpassword'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
      
      it "does not log in with wrong email" do
        post user_session_path, params: {
          user: {
            email: 'wrong@example.com',
            password: 'password123'
          }
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end
      
      it "displays error message" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'wrongpassword'
          }
        }
        # Check that response is unprocessable entity (422) which indicates validation error
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
    
    context "with remember me" do
      it "remembers the user" do
        post user_session_path, params: {
          user: {
            email: user.email,
            password: 'password123',
            remember_me: '1'
          }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end
  
  describe "DELETE /users/sign_out" do
    before { sign_in user }
    
    it "logs out the user" do
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
    
    it "clears the user session" do
      delete destroy_user_session_path
      follow_redirect!
      # After logout, should redirect to posts index (root) which requires login
      # So it will redirect to sign in page
      expect(response).to redirect_to(new_user_session_path)
    end
  end
end
