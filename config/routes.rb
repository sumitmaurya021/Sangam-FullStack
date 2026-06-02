Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions:      'users/sessions',
    registrations: 'users/registrations',
    passwords:     'users/passwords',
    confirmations: 'users/confirmations',
    unlocks:       'users/unlocks'
  }
  
  root to: "posts#index"
  
  # Posts — with edit/update + bookmark
  resources :posts, only: [:index, :show, :create, :edit, :update, :destroy] do
    member do
      post   'like',      to: 'likes#create'
      delete 'unlike',    to: 'likes#destroy'
      post   'share',     to: 'shares#create'
      post   'bookmark',  to: 'bookmarks#create'
      delete 'unbookmark', to: 'bookmarks#destroy'
    end
    resources :comments, only: [:create, :destroy]
  end

  # Bookmarks — saved posts page
  resources :bookmarks, only: [:index]

  # Stories (Instagram-style)
  resources :stories, only: [:create, :show, :destroy] do
    member do
      post :view
    end
    collection do
      get :active  # JSON feed for stories bar
    end
  end

  # Reels
  resources :reels, only: [:index, :create, :destroy] do
    member do
      post   'like',   to: 'reels#like'
      delete 'unlike', to: 'reels#unlike'
      post   'view',   to: 'reels#view'
    end
    resources :reel_comments, only: [:index, :create, :destroy]
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

  # Groups (Facebook-style)
  resources :groups do
    member do
      post   :join
      delete :leave
      post   'approve_member', to: 'groups#approve_member'
      delete 'remove_member',  to: 'groups#remove_member'
    end
  end

  # Events (Facebook-style)
  resources :events do
    member do
      post :respond_to_event
    end
  end

  # Global Search
  get '/search', to: 'search#index', as: 'search'

  # Hashtag explore page
  get '/hashtag/:name', to: 'hashtags#show', as: 'hashtag'
  get '/explore',       to: 'hashtags#explore', as: 'explore'

  # Chat / Conversations
  resources :conversations, only: [:index, :show, :create, :destroy] do
    member do
      get :messages
    end
    resources :messages, only: [:create, :destroy]
  end

  # Notifications
  resources :notifications, only: [:index, :destroy] do
    collection do
      get   :dropdown
      patch :mark_all_read
    end
    member do
      patch :mark_read
    end
  end

  # Action Cable mount
  mount ActionCable.server => '/cable'

  # Super Admin Dashboard
  namespace :admin do
    get 'dashboard',  to: 'dashboard#index',        as: 'dashboard'
    get 'users',      to: 'dashboard#users',         as: 'users'
    get 'posts',      to: 'dashboard#posts',         as: 'posts'
    get 'user/:id',   to: 'dashboard#user_details',  as: 'user_details'
  end
  
  # Music search (proxies Deezer API to avoid CORS)
  get 'music/search', to: 'music_search#search', as: 'music_search'

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
