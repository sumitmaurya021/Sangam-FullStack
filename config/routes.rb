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
  get 'profile/:id', to: 'profiles#show', as: 'profile'
  get 'profile/:id/friends', to: 'profiles#friends', as: 'profile_friends'
  
  # Friendships
  resources :friendships, only: [:create, :destroy] do
    member do
      patch :accept
      patch :reject
    end
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
