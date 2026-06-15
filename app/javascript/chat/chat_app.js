import { ConversationChannel } from "chat/conversation_channel";
import { UserChatChannel } from "chat/user_chat_channel";
import { PresenceChannel } from "chat/presence_channel";
import { WebRTCManager } from "chat/webrtc_manager";
import { EmojiPicker } from "chat/emoji_picker";
import { GifPicker } from "chat/gif_picker";

export class ChatApp {
  constructor(currentUserId) {
    this.currentUserId = currentUserId;
    this.conversationId = null;
    this.otherUserId = null;
    this.conversationChannel = null;
    this.webrtc = null;
    this.typingTimer = null;
    this.isTyping = false;
    this.oldestMessageId = null;
    this.pendingAttachment = null;
    this.pendingAttachmentType = null;
    this._seenMessageIds = new Set();

    // Always subscribe to user-level channels
    this._userChatChannel = new UserChatChannel(currentUserId, this);
    this._presenceChannel = new PresenceChannel(this);
  }

  // ─── List Page ─────────────────────────────────────────────────────────────

  initConversationsList() {
    this.conversationsPath = window.CHAT_DATA?.conversationsPath || "/conversations";
    this._setupNewMessageModal();
    this._setupConversationSearch();
    this._setupConvLongPress();
  }

  // ─── Conversation View Page ────────────────────────────────────────────────

  initConversationView(data) {
    this.conversationId   = data.conversationId;
    this.otherUserId      = data.otherUserId;
    this.messagesPath     = data.messagesPath;
    this.conversationsPath = data.conversationsPath;
    this.loadMorePath     = data.loadMorePath;

    // Subscribe to this conversation's channel
    this.conversationChannel = new ConversationChannel(this.conversationId, this);

    // WebRTC
    this.webrtc = new WebRTCManager(this);

    // UI setup
    this._setupMessageInput();
    this._setupAttachments();
    this._setupCallButtons();
    this._setupInfoPanel();
    this._setupEmojiPicker();
    this._setupGifPicker();
    this._setupBackButton();
    this._setupConversationSearch();
    this._markActiveConversation();
    this._scrollToBottom();
    this._checkLoadMore();
    this._setupConvLongPress();

    // Seed seen IDs from already-rendered messages
    document.querySelectorAll(".message-wrapper[data-message-id]").forEach(el => {
      this._seenMessageIds.add(parseInt(el.dataset.messageId));
    });
  }

  // ─── Send Message ──────────────────────────────────────────────────────────

  sendMessage() {
    const input = document.getElementById("messageInput");
    const body  = input?.value?.trim();

    if (!body && !this.pendingAttachment) return;

    const formData = new FormData();
    if (this.pendingAttachment) {
      formData.append("message[attachment]", this.pendingAttachment);
      formData.append("message[message_type]", this.pendingAttachmentType);
      if (body) formData.append("message[body]", body);
    } else {
      formData.append("message[body]", body);
      formData.append("message[message_type]", "text");
    }

    // Clear input immediately for better UX
    if (input) { input.value = ""; input.style.height = "auto"; }
    this._clearAttachment();
    this._stopTyping();

    fetch(this.messagesPath, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: formData
    })
    .then(r => r.json())
    .then(data => {
      if (!data.success) {
        // Restore input on failure
        if (input) input.value = body;
        console.error("Send failed:", data.errors);
        this._showToast("Failed to send message", "error");
      }
      // SUCCESS: message will appear via Action Cable broadcast — no DOM manipulation here
    })
    .catch(err => {
      if (input) input.value = body;
      console.error("Send error:", err);
      this._showToast("Network error — message not sent", "error");
    });
  }

  // ─── Incoming Message (from Action Cable) ─────────────────────────────────

  handleNewMessage(data) {
    const msg = data.message;
    if (!msg) return;

    // Deduplicate
    if (this._seenMessageIds.has(msg.id)) return;
    this._seenMessageIds.add(msg.id);

    const list = document.getElementById("messagesList");
    if (!list) return;

    list.insertAdjacentHTML("beforeend", this._buildMessageHTML(msg));
    this._scrollToBottom();

    // Mark as read if other user sent it
    if (msg.user_id !== this.currentUserId) {
      this.conversationChannel?.markRead();
    }

    this._updateConversationPreview(msg);
  }

  handleMessageDeleted(data) {
    const el = document.getElementById(`message-${data.message_id}`);
    if (!el) return;
    const bubble = el.querySelector(".message-bubble");
    if (bubble) {
      bubble.classList.add("deleted");
      bubble.innerHTML = '<em class="message-deleted-text">Message deleted</em>';
    }
    el.querySelector(".message-actions")?.remove();
  }

  handleMessagesRead(data) {
    if (data.reader_id !== this.otherUserId) return;
    document.querySelectorAll(".sent-indicator").forEach(el => {
      el.outerHTML = `<span class="seen-indicator" title="Seen">
        <svg width="16" height="10" viewBox="0 0 16 10" fill="#0084ff">
          <path d="M1 5l3 3 5-7M6 8l3-3 5-7" stroke="#0084ff" stroke-width="1.5" fill="none" stroke-linecap="round"/>
        </svg></span>`;
    });
  }

  handleTyping(data) {
    if (data.user_id === this.currentUserId) return;
    const el = document.getElementById("typingIndicator");
    if (!el) return;
    el.style.display = data.is_typing ? "flex" : "none";
    if (data.is_typing) this._scrollToBottom();
  }

  // ─── Presence ──────────────────────────────────────────────────────────────

  handlePresenceUpdate(data) {
    // Update all online dots with this user's id
    document.querySelectorAll(`[data-user-id="${data.user_id}"]`).forEach(dot => {
      dot.className = `messenger-online-dot ${data.online ? 'online' : 'offline'}`;
    });

    if (data.user_id !== this.otherUserId) return;

    const statusEl = document.getElementById("chatUserStatus");
    const headerDot = document.getElementById("headerOnlineDot");
    const infoPanelStatus = document.getElementById("infoPanelStatus");

    // Build the status text — use real last_seen_at timestamp when offline
    let statusText;
    if (data.online) {
      statusText = '<span class="status-online">Active now</span>';
    } else if (data.last_seen_at) {
      statusText = `Active ${this._timeAgo(new Date(data.last_seen_at))} ago`;
    } else {
      statusText = 'Offline';
    }

    if (statusEl) {
      statusEl.innerHTML = statusText;
    }
    if (headerDot) {
      headerDot.className = `messenger-online-dot ${data.online ? 'online' : 'offline'}`;
    }
    if (infoPanelStatus) {
      infoPanelStatus.innerHTML = statusText;
    }
  }

  // Returns a human-readable relative time string (e.g. "5 minutes", "2 hours")
  _timeAgo(date) {
    const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
    if (seconds < 60)  return 'a few seconds';
    const minutes = Math.floor(seconds / 60);
    if (minutes < 60)  return `${minutes} minute${minutes !== 1 ? 's' : ''}`;
    const hours = Math.floor(minutes / 60);
    if (hours < 24)    return `${hours} hour${hours !== 1 ? 's' : ''}`;
    const days = Math.floor(hours / 24);
    return `${days} day${days !== 1 ? 's' : ''}`;
  }

  // ─── Notification (UserChatChannel) ───────────────────────────────────────

  handleNewMessageNotification(data) {
    this._updateUnreadBadge(data.unread_count);

    // If we're on the conversation page for this conversation, ignore (already handled)
    if (this.conversationId && data.conversation_id === this.conversationId) return;

    // Update sidebar preview if visible
    this._updateConversationPreviewById(data.conversation_id, data.message);
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  deleteMessage(messageId) {
    if (!confirm("Delete this message?")) return;

    fetch(`${this.messagesPath}/${messageId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    })
    .then(r => r.json())
    .then(data => { if (!data.success) console.error("Delete failed:", data.error); })
    .catch(err => console.error("Delete error:", err));
  }

  // ─── Delete Conversation ───────────────────────────────────────────────────

  deleteConversation() {
    if (!confirm("Delete this entire conversation? This cannot be undone.")) return;

    const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
    const url = `${this.conversationsPath}/${this.conversationId}`;

    fetch(url, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "application/json",
        "Content-Type": "application/json"
      }
    })
    .then(r => {
      // Rails redirect responds with 302 or JSON — either way go to conversations list
      window.location.href = this.conversationsPath;
    })
    .catch(err => {
      console.error("Delete conversation error:", err);
      this._showToast("Could not delete conversation.", "error");
    });
  }

  // ─── Load More ─────────────────────────────────────────────────────────────

  loadMoreMessages() {
    if (!this.oldestMessageId) return;

    fetch(`${this.loadMorePath}?before_id=${this.oldestMessageId}`, {
      headers: { "Accept": "application/json" }
    })
    .then(r => r.json())
    .then(data => {
      const list = document.getElementById("messagesList");
      if (!list || !data.messages?.length) return;

      const fragment = document.createDocumentFragment();
      const tmp = document.createElement("div");
      data.messages.forEach(msg => {
        this._seenMessageIds.add(msg.id);
        tmp.innerHTML = this._buildMessageHTML(msg);
        fragment.appendChild(tmp.firstElementChild);
      });
      list.insertBefore(fragment, list.firstElementChild);
      this.oldestMessageId = data.messages[0].id;

      const btn = document.getElementById("loadMoreBtn");
      if (btn) btn.style.display = data.has_more ? "flex" : "none";
    });
  }

  // ─── Image Viewer ──────────────────────────────────────────────────────────

  openImageViewer(url) {
    const overlay = document.createElement("div");
    overlay.className = "image-viewer-overlay";
    overlay.innerHTML = `
      <div class="image-viewer-content">
        <button class="image-viewer-close" onclick="this.closest('.image-viewer-overlay').remove()">✕</button>
        <img src="${url}" class="image-viewer-img" alt="Image">
        <a href="${url}" download class="image-viewer-download">⬇ Download</a>
      </div>`;
    overlay.addEventListener("click", e => { if (e.target === overlay) overlay.remove(); });
    document.body.appendChild(overlay);
  }

  // ─── GIF / Emoji helpers ───────────────────────────────────────────────────

  async _sendGifFromUrl(gifUrl) {
    document.getElementById("gifPickerModal").style.display = "none";
    try {
      const res  = await fetch(gifUrl);
      const blob = await res.blob();
      const file = new File([blob], "tenor.gif", { type: "image/gif" });
      this._setAttachment(file, "gif");
      this.sendMessage();
    } catch (e) { console.error("GIF send error:", e); }
  }

  _sendTextAsMessage(text) {
    document.getElementById("gifPickerModal").style.display = "none";
    const input = document.getElementById("messageInput");
    if (input) { input.value = text; this.sendMessage(); }
  }

  // ─── Private: UI Setup ────────────────────────────────────────────────────

  _setupMessageInput() {
    const input   = document.getElementById("messageInput");
    const sendBtn = document.getElementById("sendBtn");
    if (!input) return;

    input.addEventListener("input", () => {
      input.style.height = "auto";
      input.style.height = Math.min(input.scrollHeight, 120) + "px";
      this._handleTypingIndicator(input.value.length > 0);
    });

    input.addEventListener("keydown", e => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
    });

    sendBtn?.addEventListener("click", () => this.sendMessage());
    input.focus();
  }

  _handleTypingIndicator(isTyping) {
    if (isTyping && !this.isTyping) {
      this.isTyping = true;
      this.conversationChannel?.sendTyping(true);
    }
    clearTimeout(this.typingTimer);
    this.typingTimer = setTimeout(() => this._stopTyping(), 2000);
  }

  _stopTyping() {
    if (this.isTyping) {
      this.isTyping = false;
      this.conversationChannel?.sendTyping(false);
    }
  }

  _setupAttachments() {
    const fileInput  = document.getElementById("fileInput");
    const imageInput = document.getElementById("imageInput");

    document.getElementById("attachBtn")?.addEventListener("click", () => fileInput?.click());
    document.getElementById("imageBtn")?.addEventListener("click", () => imageInput?.click());

    fileInput?.addEventListener("change", e => {
      const f = e.target.files[0];
      if (f) this._setAttachment(f, "file");
    });

    imageInput?.addEventListener("change", e => {
      const f = e.target.files[0];
      if (f) this._setAttachment(f, f.type.startsWith("video/") ? "video" : "image");
    });

    document.getElementById("removeAttachment")?.addEventListener("click", () => this._clearAttachment());
  }

  _setAttachment(file, type) {
    this.pendingAttachment     = file;
    this.pendingAttachmentType = type;
    const preview = document.getElementById("attachmentPreview");
    const inner   = document.getElementById("attachmentPreviewInner");
    if (!preview || !inner) return;
    preview.style.display = "flex";
    if (type === "image") {
      inner.innerHTML = `<img src="${URL.createObjectURL(file)}" class="attachment-preview-img">`;
    } else if (type === "video") {
      inner.innerHTML = `<video src="${URL.createObjectURL(file)}" class="attachment-preview-img" controls></video>`;
    } else {
      inner.innerHTML = `<div class="attachment-preview-file">📎 ${file.name}</div>`;
    }
  }

  _clearAttachment() {
    this.pendingAttachment     = null;
    this.pendingAttachmentType = null;
    const preview = document.getElementById("attachmentPreview");
    if (preview) preview.style.display = "none";
    const fi = document.getElementById("fileInput");
    const ii = document.getElementById("imageInput");
    if (fi) fi.value = "";
    if (ii) ii.value = "";
  }

  _setupCallButtons() {
    document.getElementById("audioCallBtn")?.addEventListener("click", () => this.webrtc?.startCall("audio"));
    document.getElementById("videoCallBtn")?.addEventListener("click", () => this.webrtc?.startCall("video"));
    document.getElementById("infoPanelAudioCall")?.addEventListener("click", () => this.webrtc?.startCall("audio"));
    document.getElementById("infoPanelVideoCall")?.addEventListener("click", () => this.webrtc?.startCall("video"));
    document.getElementById("endCallBtn")?.addEventListener("click", () => this.webrtc?.endCall());
    document.getElementById("muteBtn")?.addEventListener("click", () => this.webrtc?.toggleMute());
    document.getElementById("videoToggleBtn")?.addEventListener("click", () => this.webrtc?.toggleVideo());
    document.getElementById("rejectCallBtn")?.addEventListener("click", () => this.webrtc?.rejectCall());
    document.getElementById("acceptCallBtn")?.addEventListener("click", () => this.webrtc?.acceptCall());
  }

  _setupInfoPanel() {
    document.getElementById("chatInfoBtn")?.addEventListener("click", () => {
      const p = document.getElementById("chatInfoPanel");
      if (p) p.style.display = p.style.display === "none" ? "flex" : "none";
    });
    document.getElementById("closeInfoPanel")?.addEventListener("click", () => {
      const p = document.getElementById("chatInfoPanel");
      if (p) p.style.display = "none";
    });
  }

  _setupEmojiPicker() {
    const picker = new EmojiPicker();
    document.getElementById("emojiBtn")?.addEventListener("click", e => {
      e.stopPropagation();
      picker.toggle(e.target, emoji => {
        const input = document.getElementById("messageInput");
        if (input) {
          const pos = input.selectionStart;
          input.value = input.value.slice(0, pos) + emoji + input.value.slice(pos);
          input.focus();
        }
      });
    });
  }

  _setupGifPicker() {
    const gp = new GifPicker(this);
    document.getElementById("gifBtn")?.addEventListener("click", e => { e.stopPropagation(); gp.toggle(); });
    document.getElementById("closeGifPicker")?.addEventListener("click", () => gp.hide());
  }

  _setupBackButton() {
    document.getElementById("backBtn")?.addEventListener("click", () => {
      // On mobile: go back to sidebar instead of navigating away
      const layout = document.getElementById("messengerLayout");
      if (layout && window.innerWidth <= 768) {
        layout.classList.remove("chat-open");
      } else {
        window.location.href = this.conversationsPath;
      }
    });
  }

  _setupNewMessageModal() {
    const modal       = document.getElementById("newMessageModal");
    const openModal   = () => { if (modal) modal.style.display = "flex"; this._loadFriendsList(); };

    document.getElementById("newMessageBtn")?.addEventListener("click", openModal);
    document.getElementById("startNewChatBtn")?.addEventListener("click", openModal);
    document.getElementById("closeNewMessageModal")?.addEventListener("click", () => {
      if (modal) modal.style.display = "none";
    });
    modal?.addEventListener("click", e => { if (e.target === modal) modal.style.display = "none"; });
    document.getElementById("friendSearch")?.addEventListener("input", e => this._filterFriendsList(e.target.value));
  }

  _setupConversationSearch() {
    document.getElementById("conversationSearch")?.addEventListener("input", e => {
      const q = e.target.value.toLowerCase();
      document.querySelectorAll(".messenger-conversation-item").forEach(item => {
        const name = item.querySelector(".messenger-conversation-name")?.textContent?.toLowerCase();
        item.style.display = name?.includes(q) ? "flex" : "none";
      });
    });
  }

  // ─── Long-press context menu on conversation items ─────────────────────────

  _setupConvLongPress() {
    const LONG_PRESS_MS = 600;

    document.querySelectorAll(".messenger-conversation-item-wrapper").forEach(wrapper => {
      let timer      = null;
      let didLong    = false;   // did we fire the long-press?
      let startX     = 0;
      let startY     = 0;

      // ── helpers ──────────────────────────────────────────────────────────
      const open = () => {
        didLong = true;
        wrapper.classList.remove("pressing");
        this._openConvContextMenu(wrapper);
      };

      const cancel = () => {
        clearTimeout(timer);
        timer = null;
        wrapper.classList.remove("pressing");
      };

      // ── mouse ─────────────────────────────────────────────────────────────
      wrapper.addEventListener("mousedown", (e) => {
        if (e.button !== 0) return;          // left-click only
        didLong = false;
        startX  = e.clientX;
        startY  = e.clientY;
        wrapper.classList.add("pressing");
        timer = setTimeout(open, LONG_PRESS_MS);
      });

      wrapper.addEventListener("mouseup", () => cancel());
      wrapper.addEventListener("mouseleave", () => cancel());

      wrapper.addEventListener("mousemove", (e) => {
        // cancel if moved more than 5px
        if (Math.abs(e.clientX - startX) > 5 || Math.abs(e.clientY - startY) > 5) cancel();
      });

      // Block the click that fires right after a long-press
      wrapper.addEventListener("click", (e) => {
        if (didLong) {
          e.preventDefault();
          e.stopImmediatePropagation();
          didLong = false;
        }
      }, true);   // capture phase — runs before link's click

      // ── touch ─────────────────────────────────────────────────────────────
      wrapper.addEventListener("touchstart", (e) => {
        didLong = false;
        startX  = e.touches[0].clientX;
        startY  = e.touches[0].clientY;
        wrapper.classList.add("pressing");
        timer = setTimeout(open, LONG_PRESS_MS);
      }, { passive: true });

      wrapper.addEventListener("touchend",    () => cancel());
      wrapper.addEventListener("touchcancel", () => cancel());

      wrapper.addEventListener("touchmove", (e) => {
        const t = e.touches[0];
        if (Math.abs(t.clientX - startX) > 8 || Math.abs(t.clientY - startY) > 8) cancel();
      }, { passive: true });
    });
  }

  _openConvContextMenu(wrapper) {
    this._closeConvContextMenu();

    const deleteUrl = wrapper.dataset.convUrl;
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    if (!deleteUrl) return;

    // ── backdrop (behind menu, closes on click) ───────────────────────────
    const backdrop = document.createElement("div");
    backdrop.className = "conv-context-backdrop";
    backdrop.id        = "convContextBackdrop";
    backdrop.addEventListener("click", () => this._closeConvContextMenu());
    document.body.appendChild(backdrop);

    // ── menu ──────────────────────────────────────────────────────────────
    const menu = document.createElement("div");
    menu.className = "conv-context-menu";
    menu.id        = "convContextMenu";
    menu.innerHTML = `
      <button class="conv-context-menu-item danger" id="convMenuDelete">
        <svg width="16" height="16" viewBox="0 0 16 16" fill="currentColor">
          <path d="M6.5 1.5h3a.5.5 0 010 1h-3a.5.5 0 010-1zM2 3.5h12l-.9 9.5a1 1 0 01-1 .9H3.9a1 1 0 01-1-.9L2 3.5zm3 2v5.5h1V5.5H5zm3 0v5.5h1V5.5H8zm3 0v5.5h1V5.5h-1z"/>
        </svg>
        Delete Conversation
      </button>`;

    // Position relative to wrapper
    const rect = wrapper.getBoundingClientRect();
    menu.style.position = "fixed";
    menu.style.top      = `${rect.top + rect.height / 2}px`;
    menu.style.left     = `${rect.left + 60}px`;
    menu.style.transform = "translateY(-50%) scale(0.85)";
    document.body.appendChild(menu);

    requestAnimationFrame(() => {
      menu.style.transition = "opacity 0.15s ease, transform 0.15s ease";
      menu.style.opacity    = "1";
      menu.style.transform  = "translateY(-50%) scale(1)";
    });

    // ── delete handler ────────────────────────────────────────────────────
    menu.querySelector("#convMenuDelete").addEventListener("click", (e) => {
      e.stopPropagation();
      this._closeConvContextMenu();

      if (!confirm("Delete this conversation? This cannot be undone.")) return;

      fetch(deleteUrl, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": csrfToken,
          "Accept":       "application/json",
          "Content-Type": "application/json"
        }
      })
      .then(res => {
        if (res.ok) {
          // Remove the wrapper from DOM immediately for instant feedback
          wrapper.remove();
          // If we're currently viewing this conversation, go back to list
          const convId = wrapper.dataset.convId;
          if (this.conversationId && String(this.conversationId) === String(convId)) {
            window.location.href = this.conversationsPath || "/conversations";
          }
        } else {
          res.text().then(t => console.error("Delete failed:", res.status, t));
          this._showToast("Could not delete conversation.", "error");
        }
      })
      .catch(err => {
        console.error("Delete error:", err);
        this._showToast("Network error.", "error");
      });
    });
  }

  _closeConvContextMenu() {
    const menu     = document.getElementById("convContextMenu");
    const backdrop = document.getElementById("convContextBackdrop");
    if (menu) {
      menu.style.opacity   = "0";
      menu.style.transform = "translateY(-50%) scale(0.85)";
      setTimeout(() => menu.remove(), 150);
    }
    backdrop?.remove();
  }

  _loadFriendsList() {
    const list = document.getElementById("friendsList");
    if (!list) return;
    list.innerHTML = '<div class="messenger-loading"><div class="messenger-loading-spinner"></div></div>';

    fetch("/profiles/friends_list", { headers: { "Accept": "application/json" } })
      .then(r => r.json())
      .then(friends => {
        if (!friends.length) {
          list.innerHTML = '<p class="messenger-error">No friends yet</p>';
          return;
        }
        list.innerHTML = friends.map(f => `
          <div class="messenger-friend-item" onclick="chatApp.startConversation(${f.id})">
            <div class="messenger-avatar-wrapper" style="width:40px;height:40px;">
              ${f.avatar
                ? `<img src="${f.avatar}" class="messenger-avatar" style="width:40px;height:40px;" alt="${this._escapeHtml(f.name)}">`
                : `<div class="messenger-avatar-placeholder" style="width:40px;height:40px;font-size:16px;">${f.name[0].toUpperCase()}</div>`}
              <span class="messenger-online-dot ${f.online ? 'online' : 'offline'}"></span>
            </div>
            <span class="messenger-friend-name">${this._escapeHtml(f.name)}</span>
          </div>`).join("");
      })
      .catch(() => { list.innerHTML = '<p class="messenger-error">Could not load friends</p>'; });
  }

  _filterFriendsList(query) {
    document.querySelectorAll(".messenger-friend-item").forEach(item => {
      const name = item.querySelector(".messenger-friend-name")?.textContent?.toLowerCase();
      item.style.display = name?.includes(query.toLowerCase()) ? "flex" : "none";
    });
  }

  startConversation(recipientId) {
    fetch("/conversations", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      },
      body: JSON.stringify({ recipient_id: recipientId })
    })
    .then(r => r.json())
    .then(data => {
      if (data.conversation_id) window.location.href = `/conversations/${data.conversation_id}`;
    });
  }

  _scrollToBottom(smooth = false) {
    const area = document.getElementById("messagesArea");
    if (area) area.scrollTo({ top: area.scrollHeight, behavior: smooth ? "smooth" : "auto" });
  }

  _checkLoadMore() {
    const list = document.getElementById("messagesList");
    if (!list) return;
    const msgs = list.querySelectorAll(".message-wrapper");
    if (msgs.length >= 50) {
      const btn = document.getElementById("loadMoreBtn");
      if (btn) btn.style.display = "flex";
      this.oldestMessageId = msgs[0]?.dataset?.messageId;
    }
  }

  _markActiveConversation() {
    if (!this.conversationId) return;
    document.querySelectorAll(".messenger-conversation-item").forEach(item => {
      item.classList.toggle("active", item.dataset.conversationId == this.conversationId);
    });
  }

  _updateConversationPreview(msg) {
    if (!this.conversationId) return;
    this._updateConversationPreviewById(this.conversationId, msg);
  }

  _updateConversationPreviewById(convId, msg) {
    const item = document.querySelector(`[data-conversation-id="${convId}"]`);
    if (!item) return;
    const lastMsgEl = item.querySelector(".messenger-last-message");
    const timeEl    = item.querySelector(".messenger-conversation-time");
    if (lastMsgEl) {
      lastMsgEl.textContent = msg.message_type !== "text" ? `📎 ${msg.message_type}` : (msg.body || "").substring(0, 35);
    }
    if (timeEl) timeEl.textContent = "Just now";
  }

  _updateUnreadBadge(count) {
    const badge = document.getElementById("chatUnreadBadge");
    if (!badge) return;
    if (count > 0) {
      badge.textContent = count;
      badge.style.display = "flex";
    } else {
      badge.textContent = "";
      badge.style.display = "none";
    }
  }

  _showToast(msg, type = "info") {
    const t = document.createElement("div");
    t.className = `chat-toast ${type === "error" ? "chat-toast-error" : ""}`;
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 3000);
  }

  // ─── Build Message HTML ────────────────────────────────────────────────────

  _buildMessageHTML(msg) {
    const isMine = msg.user_id === this.currentUserId;

    const avatarHtml = msg.sender_avatar
      ? `<img src="${msg.sender_avatar}" class="message-avatar" alt="${this._escapeHtml(msg.sender_name)}">`
      : `<div class="message-avatar-placeholder">${(msg.sender_name || "?")[0].toUpperCase()}</div>`;

    let content = "";
    if (msg.deleted) {
      content = '<em class="message-deleted-text">Message deleted</em>';
    } else if (msg.message_type === "text") {
      content = `<p class="message-text">${this._escapeHtml(msg.body)}</p>`;
    } else if ((msg.message_type === "image" || msg.message_type === "gif") && msg.attachment_url) {
      content = `<div class="message-image-wrapper">
        <img src="${msg.attachment_url}" class="message-image${msg.message_type === 'gif' ? ' message-gif' : ''}"
             loading="lazy" onclick="chatApp.openImageViewer('${msg.attachment_url}')">
      </div>`;
    } else if (msg.message_type === "video" && msg.attachment_url) {
      content = `<div class="message-video-wrapper">
        <video controls class="message-video" preload="metadata"><source src="${msg.attachment_url}"></video>
      </div>`;
    } else if (msg.message_type === "audio" && msg.attachment_url) {
      content = `<div class="message-audio-wrapper">
        <audio controls class="message-audio"><source src="${msg.attachment_url}"></audio>
      </div>`;
    } else if (msg.message_type === "file" && msg.attachment_url) {
      content = `<div class="message-file-wrapper">
        <div class="message-file-icon">📎</div>
        <div class="message-file-info"><span class="message-file-name">${this._escapeHtml(msg.attachment_filename || "File")}</span></div>
        <a href="${msg.attachment_url}" download class="message-file-download">⬇</a>
      </div>`;
    }

    const statusHtml = isMine ? `
      <span class="message-status" data-message-id="${msg.id}">
        ${msg.read_at
          ? `<span class="seen-indicator" title="Seen">
              <svg width="16" height="10" viewBox="0 0 16 10" fill="#0084ff">
                <path d="M1 5l3 3 5-7M6 8l3-3 5-7" stroke="#0084ff" stroke-width="1.5" fill="none" stroke-linecap="round"/>
              </svg></span>`
          : `<span class="sent-indicator">
              <svg width="12" height="10" viewBox="0 0 12 10" fill="none">
                <path d="M1 5l3 3 7-7" stroke="#8a8d91" stroke-width="1.5" stroke-linecap="round"/>
              </svg></span>`}
      </span>` : "";

    const actionsHtml = isMine && !msg.deleted ? `
      <div class="message-actions" data-message-id="${msg.id}">
        <button class="message-action-btn delete-message-btn"
                onclick="chatApp.deleteMessage(${msg.id})" title="Delete">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="currentColor">
            <path d="M5.5 1.5h3a.5.5 0 010 1h-3a.5.5 0 010-1zM2 3.5h10l-.8 8H2.8L2 3.5zm2 2v4h1v-4H4zm3 0v4h1v-4H7z"/>
          </svg>
        </button>
      </div>` : "";

    const time = new Date(msg.created_at).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });

    return `
      <div class="message-wrapper ${isMine ? 'mine' : 'theirs'}"
           id="message-${msg.id}" data-message-id="${msg.id}">
        ${!isMine ? `<div class="message-avatar-wrapper">${avatarHtml}</div>` : ""}
        <div class="message-content-wrapper">
          <div class="message-bubble ${msg.deleted ? 'deleted' : ''}">${content}</div>
          <div class="message-meta">
            <span class="message-time">${time}</span>
            ${statusHtml}
          </div>
          ${actionsHtml}
        </div>
      </div>`;
  }

  _escapeHtml(str) {
    if (!str) return "";
    return str
      .replace(/&/g, "&amp;").replace(/</g, "&lt;")
      .replace(/>/g, "&gt;").replace(/"/g, "&quot;")
      .replace(/\n/g, "<br>");
  }
}
