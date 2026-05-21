require 'rails_helper'

RSpec.describe "Users::Registrations", type: :request do
  describe "GET /users/sign_up" do
    it "returns http success" do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
    end
    
    it "displays the signup page" do
      get new_user_registration_path
      expect(response.body).to include('Sangam')
      expect(response.body).to include('Create account')
    end
    
    it "includes CSS stylesheet link" do
      get new_user_registration_path
      expect(response.body).to include('users/registrations')
    end
    
    it "has email field" do
      get new_user_registration_path
      expect(response.body).to include('Email Address')
    end
    
    it "has password fields" do
      get new_user_registration_path
      expect(response.body).to include('Password')
      expect(response.body).to include('Confirm Password')
    end
    
    it "has signup button" do
      get new_user_registration_path
      expect(response.body).to include('Sign Up')
    end
    
    it "has login link" do
      get new_user_registration_path
      expect(response.body).to include('Already have an account?')
    end
    
    it "displays terms and policy message" do
      get new_user_registration_path
      expect(response.body).to include('Terms')
      expect(response.body).to include('Data Policy')
    end
  end
  
  describe "POST /users" do
    let(:valid_attributes) do
      {
        name: Faker::Name.name,
        email: Faker::Internet.email,
        password: 'password123',
        password_confirmation: 'password123'
      }
    end
    
    context "with valid parameters" do
      it "creates a new user" do
        expect {
          post user_registration_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end
      
      it "redirects to root path" do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
      
      it "logs in the new user" do
        post user_registration_path, params: { user: valid_attributes }
        follow_redirect!
        # User should be logged in and redirected to feed
        expect(response.body).to include('feed-container')
      end
    end
    
    context "with invalid email" do
      it "does not create a user" do
        expect {
          post user_registration_path, params: {
            user: {
              email: 'invalid-email',
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        }.not_to change(User, :count)
      end
      
      it "displays error message" do
        post user_registration_path, params: {
          user: {
            email: 'invalid-email',
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
        expect(response.body).to include('error')
      end
    end
    
    context "with mismatched passwords" do
      it "does not create a user" do
        expect {
          post user_registration_path, params: {
            user: {
              email: Faker::Internet.email,
              password: 'password123',
              password_confirmation: 'different123'
            }
          }
        }.not_to change(User, :count)
      end
      
      it "displays error message" do
        post user_registration_path, params: {
          user: {
            email: Faker::Internet.email,
            password: 'password123',
            password_confirmation: 'different123'
          }
        }
        expect(response.body).to include('error')
      end
    end
    
    context "with duplicate email" do
      let!(:existing_user) { create(:user) }
      
      it "does not create a user" do
        expect {
          post user_registration_path, params: {
            user: {
              name: 'Test User',
              email: existing_user.email,
              password: 'password123',
              password_confirmation: 'password123'
            }
          }
        }.not_to change(User, :count)
      end
      
      it "displays error message" do
        post user_registration_path, params: {
          user: {
            email: existing_user.email,
            password: 'password123',
            password_confirmation: 'password123'
          }
        }
        expect(response.body).to include('already been taken')
      end
    end
    
    context "with short password" do
      it "does not create a user" do
        expect {
          post user_registration_path, params: {
            user: {
              email: Faker::Internet.email,
              password: '12345',
              password_confirmation: '12345'
            }
          }
        }.not_to change(User, :count)
      end
    end
  end
end
