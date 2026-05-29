Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations',
    passwords: 'users/passwords',
    confirmations: 'users/confirmations',
    unlocks: 'users/unlocks'
  }
  
  root to: "posts#index"
  
  # Posts
  resources :posts, only: [:index, :create, :destroy] do
    member do
      post 'like', to: 'likes#create'
      delete 'unlike', to: 'likes#destroy'
      post 'share', to: 'shares#create'
    end
    resources :comments, only: [:create, :destroy]
  end
  
  # Profiles
  get 'profiles/friends_list', to: 'profiles#friends_list', as: 'friends_list'
  get 'profiles/search',       to: 'profiles#search',       as: 'search_profiles'
  get 'profile/:id',           to: 'profiles#show',         as: 'profile'
  get 'profile/:id/friends',   to: 'profiles#friends',      as: 'profile_friends'
  
  # Friendships
  resources :friendships, only: [:create, :destroy] do
    member do
      patch :accept
      patch :reject
    end
  end

  # Chat / Conversations
  resources :conversations, only: [:index, :show, :create, :destroy] do
    member do
      get :messages
    end
    resources :messages, only: [:create, :destroy]
  end

  # Action Cable mount
  mount ActionCable.server => '/cable'

  # Super Admin Dashboard
  namespace :admin do
    get 'dashboard', to: 'dashboard#index', as: 'dashboard'
    get 'users', to: 'dashboard#users', as: 'users'
    get 'posts', to: 'dashboard#posts', as: 'posts'
    get 'user/:id', to: 'dashboard#user_details', as: 'user_details'
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
