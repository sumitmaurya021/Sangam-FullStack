import { ChatApp } from "chat/chat_app";

// Single instance — never create two ChatApp objects for same page
let _currentApp = null;
let _currentConvId = null;

function boot() {
  const data = window.CHAT_DATA;
  if (!data) return;

  // Already booted for this exact conversation — do nothing
  const convId = data.conversationId || "list";
  if (_currentApp && _currentConvId === convId) return;

  // Cleanup previous instance
  _currentApp = null;
  _currentConvId = null;
  window.chatApp = null;

  _currentConvId = convId;
  const app = new ChatApp(data.currentUserId);
  _currentApp = app;
  window.chatApp = app;

  if (data.isListPage) {
    app.initConversationsList();
  } else if (data.conversationId) {
    app.initConversationView(data);
  }
}

// Reset when navigating away
document.addEventListener("turbo:before-visit", () => {
  _currentApp = null;
  _currentConvId = null;
  window.chatApp = null;
  window.CHAT_DATA = null;
});

// chat:data-ready — fired by inline <script> in the view AFTER CHAT_DATA is set
// This is the PRIMARY trigger — only use this
document.addEventListener("chat:data-ready", boot);

// turbo:load fallback — only fires if chat:data-ready was missed
document.addEventListener("turbo:load", () => {
  if (window.CHAT_DATA) boot();
});
