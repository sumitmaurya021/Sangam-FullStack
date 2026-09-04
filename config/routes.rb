Rails.application.routes.draw do
  devise_for :users, controllers: {
    sessions:             "users/sessions",
    registrations:        "users/registrations",
    passwords:            "users/passwords",
    confirmations:        "users/confirmations",
    unlocks:              "users/unlocks",
    omniauth_callbacks:   "users/omniauth_callbacks"
  }

  # 2FA — setup, enable, disable (authenticated), verify/confirm (during login)
  get    "two_factor_auth/setup",   to: "two_factor_auth#setup",   as: "setup_two_factor_auth"
  post   "two_factor_auth/enable",  to: "two_factor_auth#enable",  as: "enable_two_factor_auth"
  delete "two_factor_auth/disable", to: "two_factor_auth#disable", as: "disable_two_factor_auth"
  get    "two_factor_auth/verify",  to: "two_factor_auth#verify",  as: "verify_two_factor_auth"
  post   "two_factor_auth/confirm", to: "two_factor_auth#confirm", as: "confirm_two_factor_auth"

  root to: "posts#index"

  # Articles (Blogging)
  resources :articles

  # AI Features
  namespace :api do
    namespace :ai do
      post "generate_caption", to: "/ai_features#generate_caption"
      post "generate_smart_replies", to: "/ai_features#generate_smart_replies"
      post 'generate_article_content', to: '/ai_features#generate_article_content'
      post 'auto_fill_listing', to: '/ai_features#auto_fill_listing'
      post 'rewrite_message', to: '/ai_features#rewrite_message'
      post 'search', to: '/ai_features#search'
      post 'translate_text', to: '/ai_features#translate_text'
      post 'copilot', to: '/ai_features#copilot'
      post 'estimate_price', to: '/ai_features#estimate_price'
      post 'negotiate_offer', to: '/ai_features#negotiate_offer'
      post 'chat_summarize', to: '/ai_features#chat_summarize'
      post 'generate_reel', to: '/ai_features#generate_reel'
      post 'article_co_writer', to: '/ai_features#article_co_writer'
    end
    post 'interactions', to: '/interactions#create'
  end

  # Posts — with edit/update + bookmark
  resources :posts, only: [ :index, :show, :create, :edit, :update, :destroy ] do
    member do
      post   "like",               to: "likes#create"
      delete "unlike",             to: "likes#destroy"
      post   "share",              to: "shares#create"
      post   "bookmark",           to: "bookmarks#create"
      delete "unbookmark",         to: "bookmarks#destroy"
      post   "share_to_story",     to: "stories#share_to_story"
      get    "share_to_story_modal", to: "stories#share_to_story_modal"
    end
    resources :comments, only: [ :create, :destroy ]
  end

  # Post Polls
  resources :polls, only: [] do
    member do
      post :vote
    end
  end

  # Bookmarks — saved posts page
  resources :bookmarks, only: [ :index ]

  # Stories (Instagram-style)
  resources :stories, only: [ :create, :show, :destroy ] do
    member do
      post :view
    end
    collection do
      get :active  # JSON feed for stories bar
    end
  end

  # Reels
  resources :reels, only: [ :index, :create, :destroy ] do
    member do
      post   "like",            to: "reels#like"
      delete "unlike",          to: "reels#unlike"
      post   "view",            to: "reels#view"
      post   "bookmark_reel",   to: "bookmarks#create"
      delete "unbookmark_reel", to: "bookmarks#destroy"
    end
    resources :reel_comments, only: [ :index, :create, :destroy ]
  end

  # Follows (Instagram-style one-way)
  resources :follows, only: [ :create, :destroy ], param: :followee_id do
    collection do
      get :following, to: "follows#following_list"
      get :followers, to: "follows#followers_list"
    end
  end

  # Profiles
  get  "profiles/friends_list",     to: "profiles#friends_list",     as: "friends_list"
  get  "profiles/search",           to: "profiles#search",           as: "search_profiles"
  post "profiles/toggle_dark_mode", to: "profiles#toggle_dark_mode", as: "profile_toggle_dark_mode"
  get  "profile/:id",               to: "profiles#show",             as: "profile"
  get  "profile/:id/friends",       to: "profiles#friends",          as: "profile_friends"
  get  "profile/:id/following",     to: "profiles#following",        as: "profile_following"
  get  "profile/:id/followers",     to: "profiles#followers",        as: "profile_followers"

  # Friendships
  resources :friendships, only: [ :create, :destroy ] do
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
      post   "approve_member", to: "groups#approve_member"
      delete "remove_member",  to: "groups#remove_member"
    end
  end

  # Events (Facebook-style)
  resources :events do
    member do
      post :respond_to_event
    end
  end

  # Global Search
  get "/search", to: "search#index", as: "search"

  # Hashtag explore page
  get "/hashtag/:name", to: "hashtags#show", as: "hashtag"
  get "/explore",       to: "hashtags#explore", as: "explore"

  # Chat / Conversations
  resources :conversations, only: [ :index, :show, :create, :destroy ] do
    member do
      get :messages
    end
    resources :messages, only: [ :create, :destroy ]
  end

  # Group Chat
  resources :group_chats, only: [ :index, :show, :create, :destroy ] do
    member do
      post   :add_member
      delete :remove_member
      delete :leave
    end
    resources :messages, only: [ :index, :create, :destroy ],
              controller: "group_chat_messages",
              as: :group_chat_messages
  end

  # Notifications
  resources :notifications, only: [ :index, :destroy ] do
    collection do
      get   :dropdown
      patch :mark_all_read
    end
    member do
      patch :mark_read
    end
  end

  # Web Push Notifications
  resources :push_subscriptions, only: [ :create ] do
    collection do
      delete :destroy
      post   :test
      get    :status
    end
  end

  # Action Cable mount
  mount ActionCable.server => "/cable"

  # Super Admin Dashboard
  namespace :admin do
    get "dashboard",  to: "dashboard#index",        as: "dashboard"
    get "users",      to: "dashboard#users",         as: "users"
    get "posts",      to: "dashboard#posts",         as: "posts"
    get "user/:id",   to: "dashboard#user_details",  as: "user_details"
    get "moderation", to: "dashboard#moderation",    as: "moderation"
    post "moderation/:id/approve", to: "dashboard#approve_moderation", as: "approve_moderation"
    post "moderation/:id/reject",  to: "dashboard#reject_moderation",  as: "reject_moderation"
  end

  # Music search (proxies Deezer API to avoid CORS)
  get "music/search", to: "music_search#search", as: "music_search"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ─── Saved Collections ──────────────────────────────────────────────────────
  resources :bookmark_collections, only: [ :index, :create, :show, :update, :destroy ] do
    member do
      patch :add_bookmark
    end
  end

  # ─── Profile Highlights ─────────────────────────────────────────────────────
  resources :profile_highlights, only: [ :create, :update, :destroy ] do
    collection do
      get "/", to: "profile_highlights#index", as: ""
    end
    member do
      post   :add_story
      delete :remove_story
      get    :stories   # GET /profile_highlights/:id/stories
    end
  end
  get "users/:user_id/highlights", to: "profile_highlights#index", as: "user_highlights"

  # ─── Close Friends ───────────────────────────────────────────────────────────
  resources :close_friends, only: [ :index, :create, :destroy ], param: :user_id

  # ─── Story Interactions (polls & Q&A) ────────────────────────────────────────
  scope "/stories/:story_id" do
    post   "poll_vote",   to: "story_interactions#poll_vote",   as: "story_poll_vote"
    post   "qa_reply",    to: "story_interactions#qa_reply",    as: "story_qa_reply"
    get    "qa_replies",  to: "story_interactions#qa_replies",  as: "story_qa_replies"
  end

  # ─── Post Collaborators ───────────────────────────────────────────────────────
  resources :posts do
    resources :collaborators, controller: "post_collaborators", only: [ :create, :destroy ] do
      member do
        patch :accept
        patch :reject
      end
    end
  end

  # ─── Link Preview ─────────────────────────────────────────────────────────────
  get "link_preview", to: "link_previews#show", as: "link_preview"

  # ─── Memories / On This Day ───────────────────────────────────────────────────
  get "memories", to: "memories#index", as: "memories"

  # ─── Fundraisers ──────────────────────────────────────────────────────────────
  resources :fundraisers, only: [ :show ] do
    member do
      post :donate
    end
  end

  # ─── Marketplace ──────────────────────────────────────────────────────────────
  resources :marketplace_listings, path: "marketplace", as: "marketplace_listing" do
    collection do
      get :my_listings
    end
    member do
      patch :mark_sold
    end
  end

  # ─── Dark Mode preference (AJAX toggle) ──────────────────────────────────────
  patch "settings/dark_mode", to: "settings#toggle_dark_mode", as: "toggle_dark_mode"

  # ─── Autonomous Digital Twin Proxy (ADTP) ──────────────────────────────────
  resource :digital_twin, only: [ :show, :update ] do
    member do
      patch :toggle
      post :test_run
    end
  end

  # ─── Self-Evolving UX Mutation ──────────────────────────────────────────────
  resource :ux_mutation, only: [ :create, :update ] do
    get :dashboard
  end

  # ─── Synapse-Stream Cross-Modal Studio ─────────────────────────────────────
  resources :synapse_streams, only: [ :index, :show, :create ] do
    member do
      post :publish
    end
  end
end



