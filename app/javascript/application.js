// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import "shared/header"
import "posts_interactions"
import "@rails/actioncable"
import "chat/init"
import "chat/chat_widget_init"
import "notifications"
import "reels"
import "stories"
import "bookmarks"
import "groups"
import "events"
import "dark_mode"
import "link_preview"
import "collections"
import "story_interactions"
import "voice_notes"

// Register Service Worker for PWA
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker')
      .then(registration => {
        console.log('ServiceWorker registered with scope:', registration.scope);
      })
      .catch(error => {
        console.error('ServiceWorker registration failed:', error);
      });
  });
}

import "trix"
import "@rails/actiontext"
