import consumer from "channels/consumer";

export class ChatWidget {
  constructor(data) {
    this.currentUserId = data.currentUserId;
    this.conversationsPath = data.conversationsPath;
    this.openWindows = {}; // conversationId -> window element
    this.maxWindows = 3;

    this._subscribeToUserChannel();
    this._subscribeToPresence();
    this._loadFriendsSidebar();
  }

  // ─── Subscribe to user notifications ──────────────────────────────────────

  _subscribeToUserChannel() {
    consumer.subscriptions.create(
      { channel: "UserChatChannel" },
      {
        received: (data) => {
          if (data.type === "new_message_notification") {
            this._handleIncomingMessage(data);
          }
        }
      }
    );
  }

  _subscribeToPresence() {
    // Only listen for updates to refresh sidebar dots.
    // Heartbeating is handled by PresenceChannel class (used in chat pages).
    // On non-chat pages (where ChatApp is not loaded), we create a minimal subscription
    // that just updates the sidebar dots without duplicating heartbeat logic.
    consumer.subscriptions.create(
      { channel: "PresenceChannel" },
      {
        connected() {
          // Perform a heartbeat so we appear online on pages that don't load ChatApp
          this.perform("heartbeat");
        },
        received: (data) => {
          if (data.type === "presence_update") {
            this._updatePresenceDot(data.user_id, data.online);
          }
        }
      }
    );
  }

  // ─── Friends Sidebar ───────────────────────────────────────────────────────

  _loadFriendsSidebar() {
    fetch("/profiles/friends_list", {
      headers: { "Accept": "application/json" }
    })
    .then(r => r.json())
    .then(friends => {
      const container = document.getElementById("chatSidebarFriends");
      if (!container) return;

      if (friends.length === 0) {
        container.innerHTML = '<p class="chat-sidebar-empty">No friends yet</p>';
        return;
      }

      container.innerHTML = friends.map(f => `
        <div class="chat-sidebar-friend" onclick="chatWidget.openChatWith(${f.id})"
             data-user-id="${f.id}" title="${f.name}">
          <div class="chat-sidebar-avatar-wrap">
            ${f.avatar
              ? `<img src="${f.avatar}" class="chat-sidebar-avatar" alt="${f.name}">`
              : `<div class="chat-sidebar-avatar-placeholder">${f.name[0].toUpperCase()}</div>`
            }
            <span class="chat-sidebar-dot ${f.online ? 'online' : 'offline'}"
                  data-presence-user="${f.id}"></span>
          </div>
        </div>
      `).join("");
    })
    .catch(() => {});
  }

  _updatePresenceDot(userId, online) {
    document.querySelectorAll(`[data-presence-user="${userId}"]`).forEach(dot => {
      dot.className = `chat-sidebar-dot ${online ? 'online' : 'offline'}`;
    });
  }

  // ─── Open Chat Window ──────────────────────────────────────────────────────

  openChatWith(userId) {
    // Create or find conversation, then open mini window
    fetch(this.conversationsPath, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ recipient_id: userId })
    })
    .then(r => r.json())
    .then(data => {
      if (data.conversation_id) {
        this._openMiniWindow(data.conversation_id, userId);
      }
    });
  }

  _openMiniWindow(conversationId, userId) {
    // If already open, focus it
    if (this.openWindows[conversationId]) {
      this.openWindows[conversationId].classList.toggle("minimized");
      return;
    }

    // Close oldest if at max
    const windowIds = Object.keys(this.openWindows);
    if (windowIds.length >= this.maxWindows) {
      this._closeMiniWindow(windowIds[0]);
    }

    // Fetch conversation data
    fetch(`/conversations/${conversationId}`, {
      headers: { "Accept": "application/json" }
    })
    .then(r => r.json())
    .then(data => {
      this._renderMiniWindow(conversationId, data);
    });
  }

  _renderMiniWindow(conversationId, data) {
    const other = data.other_user;
    const container = document.getElementById("activeChatWindows");
    if (!container) return;

    const win = document.createElement("div");
    win.className = "mini-chat-window";
    win.id = `mini-chat-${conversationId}`;
    win.dataset.conversationId = conversationId;

    win.innerHTML = `
      <div class="mini-chat-header" onclick="chatWidget._toggleMinimize(${conversationId})">
        <div class="mini-chat-user">
          ${other.avatar
            ? `<img src="${other.avatar}" class="mini-chat-avatar" alt="${other.name}">`
            : `<div class="mini-chat-avatar-placeholder">${other.name[0].toUpperCase()}</div>`
          }
          <span class="mini-chat-dot ${other.online ? 'online' : 'offline'}"
                data-presence-user="${other.id}"></span>
          <span class="mini-chat-name">${other.name}</span>
        </div>
        <div class="mini-chat-header-actions">
          <button onclick="event.stopPropagation(); chatWidget.summarizeMiniChat(${conversationId})"
                  class="mini-chat-action-btn mini-chat-ai-btn" title="✨ AI Catch-Up Summary">✨</button>
          <button onclick="event.stopPropagation(); window.location.href='/conversations/${conversationId}'"
                  class="mini-chat-action-btn" title="Open full chat">⤢</button>
          <button onclick="event.stopPropagation(); chatWidget._closeMiniWindow(${conversationId})"
                  class="mini-chat-action-btn" title="Close">✕</button>
        </div>
      </div>
      <div class="mini-chat-body" id="mini-body-${conversationId}">
        <div class="mini-chat-messages" id="mini-messages-${conversationId}">
          ${data.messages.map(m => this._buildMiniMessageHTML(m, data.other_user.id)).join("")}
        </div>
      </div>
      <div class="mini-chat-input-row">
        <input type="text" class="mini-chat-input" id="mini-input-${conversationId}"
               placeholder="Aa" data-conversation-id="${conversationId}">
        <button class="mini-chat-send-btn" onclick="chatWidget._sendMiniMessage(${conversationId})">
          <svg width="16" height="16" viewBox="0 0 20 20" fill="currentColor">
            <path d="M2 10l16-8-8 16v-8L2 10z"/>
          </svg>
        </button>
      </div>
    `;

    container.appendChild(win);
    this.openWindows[conversationId] = win;

    // Setup enter key
    const input = win.querySelector(`#mini-input-${conversationId}`);
    input?.addEventListener("keydown", e => {
      if (e.key === "Enter") this._sendMiniMessage(conversationId);
    });

    // Subscribe to channel
    this._subscribeToConversation(conversationId);
    this._scrollMiniToBottom(conversationId);
  }

  summarizeMiniChat(conversationId) {
    const win = this.openWindows[conversationId];
    if (!win) return;

    const msgNodes = win.querySelectorAll('.mini-bubble');
    const msgTexts = Array.from(msgNodes)
      .map(node => node.textContent.trim())
      .filter(t => t.length > 0)
      .slice(-15);

    const input = win.querySelector(`#mini-input-${conversationId}`);

    if (window.openAiCatchUpModal) {
      window.openAiCatchUpModal(msgTexts, { targetInput: input });
    } else if (window.showAiToast) {
      window.showAiToast("AI Catch-Up is initializing...", "info");
    }
  }

  _subscribeToConversation(conversationId) {
    consumer.subscriptions.create(
      { channel: "ConversationChannel", conversation_id: conversationId },
      {
        received: (data) => {
          if (data.type === "new_message") {
            const win = this.openWindows[conversationId];
            if (win) {
              const list = document.getElementById(`mini-messages-${conversationId}`);
              if (list) {
                list.insertAdjacentHTML("beforeend",
                  this._buildMiniMessageHTML(data.message, null));
                this._scrollMiniToBottom(conversationId);
              }
            }
          }
        }
      }
    );
  }

  _sendMiniMessage(conversationId) {
    const input = document.getElementById(`mini-input-${conversationId}`);
    const body = input?.value?.trim();
    if (!body) return;

    fetch(`/conversations/${conversationId}/messages`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ message: { body, message_type: "text" } })
    })
    .then(r => r.json())
    .then(data => {
      if (data.success && input) input.value = "";
    });
  }

  _handleIncomingMessage(data) {
    const convId = data.conversation_id;
    const win = this.openWindows[convId];

    if (win) {
      // Update existing window
      const list = document.getElementById(`mini-messages-${convId}`);
      if (list) {
        list.insertAdjacentHTML("beforeend",
          this._buildMiniMessageHTML(data.message, null));
        this._scrollMiniToBottom(convId);
      }
      // Un-minimize if minimized
      win.classList.remove("minimized");
    } else {
      // Show notification badge on messenger icon
      const badge = document.getElementById("chatUnreadBadge");
      if (badge) {
        const current = parseInt(badge.textContent) || 0;
        badge.textContent = current + 1;
        badge.style.display = "flex";
      }
    }
  }

  _toggleMinimize(conversationId) {
    const win = this.openWindows[conversationId];
    if (win) win.classList.toggle("minimized");
  }

  _closeMiniWindow(conversationId) {
    const win = this.openWindows[conversationId];
    if (win) {
      win.remove();
      delete this.openWindows[conversationId];
    }
  }

  _scrollMiniToBottom(conversationId) {
    const body = document.getElementById(`mini-body-${conversationId}`);
    if (body) body.scrollTop = body.scrollHeight;
  }

  _buildMiniMessageHTML(msg, otherUserId) {
    const isMine = msg.user_id === this.currentUserId;
    let content = "";

    if (msg.deleted) {
      content = '<em style="font-size:12px;color:#65676b;">Message deleted</em>';
    } else if (msg.message_type === "text") {
      content = this._escapeHtml(msg.body || "");
    } else if (msg.attachment_url) {
      if (msg.message_type === "image" || msg.message_type === "gif") {
        content = `<img src="${msg.attachment_url}" style="max-width:160px;border-radius:8px;">`;
      } else {
        content = `📎 ${msg.attachment_filename || "File"}`;
      }
    }

    return `
      <div class="mini-message ${isMine ? 'mine' : 'theirs'}">
        <div class="mini-bubble">${content}</div>
      </div>
    `;
  }

  _escapeHtml(str) {
    return str
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/\n/g, "<br>");
  }
}
