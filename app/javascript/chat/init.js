import { ChatApp } from "chat/chat_app";

let _app = null;
let _booted = false;

function boot() {
  if (_booted) return;
  const data = window.CHAT_DATA;
  if (!data) return;

  _booted = true;
  _app = null;
  window.chatApp = null;

  const app = new ChatApp(data.currentUserId);
  _app = app;
  window.chatApp = app;

  console.log("[Chat] Booting ChatApp for user", data.currentUserId);

  if (data.isListPage) {
    app.initConversationsList();
  } else if (data.conversationId) {
    app._conversationId = data.conversationId;
    app.initConversationView(data);
  }
}

// Reset on Turbo navigation
document.addEventListener("turbo:before-visit", () => {
  _booted = false;
  _app = null;
  window.chatApp = null;
  window.CHAT_DATA = null;
});

// turbo:load fires after full page load or Turbo navigation
document.addEventListener("turbo:load", () => {
  _booted = false; // allow re-boot on each page load
  setTimeout(boot, 50); // small delay for inline scripts to run first
});

// chat:data-ready fired by inline script in the view
document.addEventListener("chat:data-ready", () => {
  setTimeout(boot, 50);
});

// Fallback: poll until CHAT_DATA is available (handles edge cases)
let _pollCount = 0;
const _poll = setInterval(() => {
  _pollCount++;
  if (window.CHAT_DATA && !_booted) {
    boot();
  }
  if (_booted || _pollCount > 20) {
    clearInterval(_poll);
  }
}, 100);
