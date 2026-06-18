// ╔══════════════════════════════════════════════════════════════╗
// ║  GROUP CHAT — Action Cable client + message rendering       ║
// ╚══════════════════════════════════════════════════════════════╝
import consumer from "channels/consumer";

class GroupChatApp {
  constructor(data) {
    this.groupChatId   = data.groupChatId;
    this.currentUserId = data.currentUserId;
    this.currentUserName = data.currentUserName;
    this.messagesPath  = data.messagesPath;
    this.csrfToken     = document.querySelector('meta[name="csrf-token"]')?.content || '';

    this._pendingAttachment = null;   // { file, previewUrl, type }
    this._typingTimer       = null;
    this._isTyping          = false;
    this._firstMsgId        = null;   // for load-more pagination
    this._hasMore           = false;

    this._channel = null;
    this._boot();
  }

  // ── Action Cable subscription ────────────────────────────────
  _boot() {
    this._channel = consumer.subscriptions.create(
      { channel: 'GroupChatChannel', group_chat_id: this.groupChatId },
      {
        connected:    () => {},
        disconnected: () => {},
        received:     (data) => this._handleBroadcast(data)
      }
    );

    this._bindInput();
    this._scrollToBottom();
    this._setFirstMsgId();
  }

  _handleBroadcast(data) {
    switch (data.type) {
      case 'new_group_message':
        this._appendMessage(data.message);
        break;
      case 'group_message_deleted':
        this._markDeleted(data.message_id);
        break;
      case 'group_typing':
        if (data.user_id !== this.currentUserId) {
          this._showTyping(data.user_name, data.is_typing);
        }
        break;
    }
  }

  // ── Send message ─────────────────────────────────────────────
  async sendMessage() {
    const input   = document.getElementById('gcMessageInput');
    const body    = input?.value.trim();
    const hasFile = !!this._pendingAttachment;

    if (!body && !hasFile) return;

    const btn = document.getElementById('gcSendBtn');
    if (btn) btn.disabled = true;
    if (input) input.value = '';
    this._autoResize(input);

    try {
      const fd = new FormData();
      if (body) fd.append('group_chat_message[body]', body);

      if (hasFile) {
        fd.append('group_chat_message[attachment]', this._pendingAttachment.file);
        const type = this._pendingAttachment.type;
        fd.append('group_chat_message[message_type]',
          type === 'audio' ? 'audio' : (type === 'image' ? 'image' : 'file'));
        this.clearAttachment();
      } else {
        fd.append('group_chat_message[message_type]', 'text');
      }

      await fetch(this.messagesPath, {
        method:  'POST',
        headers: { 'X-CSRF-Token': this.csrfToken, Accept: 'application/json' },
        body:    fd
      });
      // Message arrives via Action Cable broadcast — no extra rendering needed
    } catch (e) {
      this._toast('Send failed. Try again.', 'error');
    } finally {
      if (btn) btn.disabled = false;
    }
  }

  // ── Delete message ───────────────────────────────────────────
  async deleteMessage(id) {
    if (!confirm('Delete this message?')) return;
    try {
      await fetch(`${this.messagesPath}/${id}`, {
        method:  'DELETE',
        headers: { 'X-CSRF-Token': this.csrfToken, Accept: 'application/json' }
      });
    } catch (e) {
      this._toast('Could not delete message.', 'error');
    }
  }

  // ── Load more (pagination) ───────────────────────────────────
  async loadMore() {
    if (!this._firstMsgId || !this._hasMore) return;
    const btn = document.getElementById('gcLoadMoreBtn');
    if (btn) btn.style.opacity = '0.5';

    try {
      const res  = await fetch(
        `${this.messagesPath}?before_id=${this._firstMsgId}`,
        { headers: { Accept: 'application/json' } }
      );
      const data = await res.json();
      const list = document.getElementById('gcMessagesList');
      const area = document.getElementById('gcMessagesArea');
      const prevScrollH = area?.scrollHeight || 0;

      // Prepend older messages
      data.messages.reverse().forEach(msg => {
        const el = this._buildMsgEl(msg);
        list?.prepend(el);
      });

      // Restore scroll position
      if (area) area.scrollTop = area.scrollHeight - prevScrollH;

      this._hasMore = data.has_more;
      this._setFirstMsgId();
      if (btn) btn.style.display = this._hasMore ? 'flex' : 'none';
    } catch (e) {
      this._toast('Could not load messages.', 'error');
    } finally {
      if (btn) btn.style.opacity = '1';
    }
  }

  // ── Attachment handling ──────────────────────────────────────
  handleAttachment(input) {
    const file = input.files[0];
    if (!file) return;
    const isImage = file.type.startsWith('image/');
    const url     = URL.createObjectURL(file);
    this._pendingAttachment = { file, previewUrl: url, type: isImage ? 'image' : 'file' };

    const preview = document.getElementById('gcAttachPreview');
    const inner   = document.getElementById('gcAttachPreviewInner');
    if (!preview || !inner) return;

    inner.innerHTML = isImage
      ? `<img src="${url}" class="attachment-preview-img" alt="preview">`
      : `<div class="attachment-preview-file">📎 ${this._esc(file.name)}</div>`;
    preview.style.display = 'flex';
    // Reset input so same file can be re-selected
    input.value = '';
  }

  clearAttachment() {
    this._pendingAttachment = null;
    const preview = document.getElementById('gcAttachPreview');
    if (preview) preview.style.display = 'none';
    document.getElementById('gcAttachPreviewInner').innerHTML = '';
  }

  // ── Typing indicator ─────────────────────────────────────────
  _sendTyping(isTyping) {
    this._channel?.perform('typing', {
      group_chat_id: this.groupChatId,
      is_typing:     isTyping
    });
  }

  _showTyping(name, isTyping) {
    const el    = document.getElementById('gcTypingIndicator');
    const label = document.getElementById('gcTypingName');
    if (!el) return;
    el.style.display = isTyping ? 'flex' : 'none';
    if (label) label.textContent = isTyping ? `${name} is typing…` : '';
  }

  // ── DOM helpers ──────────────────────────────────────────────
  _appendMessage(msg) {
    const list = document.getElementById('gcMessagesList');
    if (!list) return;

    // Deduplicate (broadcast arrives for all subscribers including sender)
    if (document.getElementById(`gc-msg-${msg.id}`)) return;

    list.appendChild(this._buildMsgEl(msg));
    this._scrollToBottom();

    // Update first-msg tracker
    if (!this._firstMsgId) this._firstMsgId = msg.id;
  }

  _buildMsgEl(msg) {
    const isMine   = msg.user.id === this.currentUserId;
    const avatarHtml = msg.user.avatar
      ? `<img src="${msg.user.avatar}" class="message-avatar" alt="${this._esc(msg.user.name)}">`
      : `<div class="message-avatar-placeholder">${msg.user.name[0].toUpperCase()}</div>`;

    let bubbleContent = '';
    if (msg.deleted) {
      bubbleContent = '<span class="message-deleted-text">Message deleted</span>';
    } else if (msg.message_type === 'image' && msg.attachment_url) {
      bubbleContent = `<div class="message-image-wrapper">
        <img src="${msg.attachment_url}" class="message-image" alt="Image">
      </div>`;
    } else if (msg.message_type === 'file' && msg.attachment_url) {
      bubbleContent = `<div class="message-file-wrapper">
        <span class="message-file-icon">📎</span>
        <div class="message-file-info">
          <div class="message-file-name">${this._esc(msg.attachment_filename || 'File')}</div>
        </div>
        <a href="${msg.attachment_url}" class="message-file-download" download target="_blank" rel="noopener">⬇</a>
      </div>`;
    } else if (msg.message_type === 'audio' && msg.attachment_url) {
      bubbleContent = `<div class="message-audio-wrapper">
        <audio controls class="message-audio">
          <source src="${msg.attachment_url}">
        </audio>
      </div>`;
    } else {
      bubbleContent = `<p class="message-text">${this._esc(msg.body || '')}</p>`;
    }

    const senderName = isMine ? '' :
      `<span class="gc-msg-sender-name">${this._esc(msg.user.name)}</span>`;

    const deleteBtn = (!msg.deleted && isMine)
      ? `<div class="message-actions">
           <button class="message-action-btn delete-message-btn"
                   onclick="gcApp.deleteMessage(${msg.id})" title="Delete">
             <svg width="14" height="14" viewBox="0 0 16 16" fill="currentColor">
               <path d="M6.5 1.5h3a.5.5 0 010 1h-3a.5.5 0 010-1zM2 3.5h12l-.9 9.5a1 1 0 01-1 .9H3.9a1 1 0 01-1-.9L2 3.5z"/>
             </svg>
           </button>
         </div>` : '';

    const time = new Date(msg.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });

    const wrapper = document.createElement('div');
    wrapper.className = `message-wrapper ${isMine ? 'mine' : 'theirs'}`;
    wrapper.id = `gc-msg-${msg.id}`;
    wrapper.innerHTML = `
      ${isMine ? '' : `<div class="message-avatar-wrapper">${avatarHtml}</div>`}
      <div class="message-content-wrapper">
        ${senderName}
        <div class="message-bubble ${msg.deleted ? 'deleted' : ''}">${bubbleContent}</div>
        <div class="message-meta"><span class="message-time">${time}</span></div>
        ${deleteBtn}
      </div>`;
    return wrapper;
  }

  _markDeleted(id) {
    const el = document.getElementById(`gc-msg-${id}`);
    if (!el) return;
    const bubble = el.querySelector('.message-bubble');
    if (bubble) {
      bubble.classList.add('deleted');
      bubble.innerHTML = '<span class="message-deleted-text">Message deleted</span>';
    }
    el.querySelector('.message-actions')?.remove();
  }

  _setFirstMsgId() {
    const first = document.querySelector('#gcMessagesList .message-wrapper');
    if (first) this._firstMsgId = parseInt(first.id.replace('gc-msg-', ''), 10);
    // Show load-more if there might be earlier messages
    const loadMore = document.getElementById('gcLoadMoreBtn');
    if (loadMore && this._firstMsgId) loadMore.style.display = 'flex';
  }

  _scrollToBottom() {
    const area = document.getElementById('gcMessagesArea');
    if (area) area.scrollTop = area.scrollHeight;
  }

  // ── Input binding (Enter to send, auto-resize, typing) ───────
  _bindInput() {
    const input = document.getElementById('gcMessageInput');
    if (!input) return;

    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        this.sendMessage();
      }
    });

    input.addEventListener('input', () => {
      this._autoResize(input);

      // Typing indicator
      if (!this._isTyping) {
        this._isTyping = true;
        this._sendTyping(true);
      }
      clearTimeout(this._typingTimer);
      this._typingTimer = setTimeout(() => {
        this._isTyping = false;
        this._sendTyping(false);
      }, 2000);
    });
  }

  _autoResize(el) {
    if (!el) return;
    el.style.height = 'auto';
    el.style.height = Math.min(el.scrollHeight, 120) + 'px';
  }

  // ── Utilities ────────────────────────────────────────────────
  _esc(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  _toast(msg, type = 'success') {
    const t = document.createElement('div');
    t.className = `chat-toast${type === 'error' ? ' chat-toast-error' : ''}`;
    t.textContent = msg;
    document.body.appendChild(t);
    setTimeout(() => t.remove(), 3000);
  }
}

// ── Boot ──────────────────────────────────────────────────────
function bootGroupChat() {
  const data = window.GC_DATA;
  if (!data || window.gcApp) return;
  window.gcApp = new GroupChatApp(data);
}

document.addEventListener('gc:data-ready', bootGroupChat);
document.addEventListener('turbo:load', () => { if (window.GC_DATA) bootGroupChat(); });
document.addEventListener('turbo:before-visit', () => {
  window.gcApp   = null;
  window.GC_DATA = null;
});
