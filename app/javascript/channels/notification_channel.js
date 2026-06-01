import consumer from "channels/consumer";

class NotificationChannel {
  constructor() {
    this._subscribe();
  }

  _subscribe() {
    consumer.subscriptions.create(
      { channel: "NotificationChannel" },
      {
        connected: () => {
          console.log("[NotificationChannel] connected");
        },
        received: (data) => {
          console.log("[NotificationChannel] received:", data.type);
          switch (data.type) {
            case "new_notification":
              this._handleNewNotification(data.notification);
              break;
            case "unread_count":
              updateNotificationBadge(data.count);
              break;
          }
        }
      }
    );
  }

  _handleNewNotification(notification) {
    // Update badge count
    const currentCount = parseInt(
      document.getElementById("notifBadge")?.textContent || "0"
    );
    updateNotificationBadge(currentCount + 1);

    // Show toast popup
    showNotificationToast(notification);

    // If dropdown is open, prepend to it
    const dropdownList = document.getElementById("notifDropdownList");
    if (dropdownList && document.getElementById("notifDropdown")?.classList.contains("show")) {
      prependNotificationToDropdown(notification, dropdownList);
    }
  }
}

// ── Badge Update ──────────────────────────────────────────────────────────────
window.updateNotificationBadge = function(count) {
  const badge = document.getElementById("notifBadge");
  const mobileBadge = document.getElementById("notifBadgeMobile");

  [badge, mobileBadge].forEach(el => {
    if (!el) return;
    if (count > 0) {
      el.textContent = count > 99 ? "99+" : count;
      el.style.display = "";
      el.classList.add("badge-pop");
      setTimeout(() => el.classList.remove("badge-pop"), 400);
    } else {
      el.style.display = "none";
      el.textContent = "";
    }
  });
};

// ── Toast Notification ────────────────────────────────────────────────────────
window.showNotificationToast = function(notification) {
  // Remove existing toast if any
  document.getElementById("notifToast")?.remove();

  const avatarHtml = notification.actor.avatar
    ? `<img src="${notification.actor.avatar}" class="notif-toast-avatar" alt="${escapeHtml(notification.actor.name)}">`
    : `<div class="notif-toast-avatar notif-toast-avatar-placeholder">${(notification.actor.name || "?")[0].toUpperCase()}</div>`;

  const iconHtml = getNotifIconHtml(notification.notification_type);

  const toast = document.createElement("div");
  toast.id = "notifToast";
  toast.className = "notif-toast notif-toast-enter";
  toast.innerHTML = `
    <div class="notif-toast-inner">
      <div class="notif-toast-avatar-wrap">
        ${avatarHtml}
        <div class="notif-toast-type-badge notif-type-${notification.icon}">
          ${iconHtml}
        </div>
      </div>
      <div class="notif-toast-content">
        <p class="notif-toast-message">${escapeHtml(notification.message)}</p>
        <span class="notif-toast-time">Just now</span>
      </div>
      <button class="notif-toast-close" onclick="this.closest('#notifToast').remove()">
        <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor">
          <path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12 19 6.41z"/>
        </svg>
      </button>
    </div>
    <div class="notif-toast-progress"></div>
  `;

  document.body.appendChild(toast);

  // Animate in
  requestAnimationFrame(() => {
    toast.classList.remove("notif-toast-enter");
    toast.classList.add("notif-toast-show");
  });

  // Auto-dismiss after 5s
  const timer = setTimeout(() => dismissToast(toast), 5000);
  toast.addEventListener("mouseenter", () => clearTimeout(timer));
  toast.addEventListener("mouseleave", () => setTimeout(() => dismissToast(toast), 2000));
};

function dismissToast(toast) {
  if (!toast || !document.body.contains(toast)) return;
  toast.classList.remove("notif-toast-show");
  toast.classList.add("notif-toast-exit");
  setTimeout(() => toast.remove(), 400);
}

// ── Dropdown Management ───────────────────────────────────────────────────────
window.toggleNotifDropdown = function() {
  const dropdown = document.getElementById("notifDropdown");
  if (!dropdown) return;

  const isOpen = dropdown.classList.toggle("show");
  if (isOpen) {
    loadNotificationsDropdown();
    // Close other dropdowns
    document.getElementById("userDropdown")?.classList.remove("show");
    document.getElementById("navDropdown")?.classList.remove("show");
  }
};

window.loadNotificationsDropdown = function() {
  const list = document.getElementById("notifDropdownList");
  if (!list) return;

  list.innerHTML = `
    <div class="notif-dropdown-loading">
      <div class="notif-spinner"></div>
      <span>Loading notifications...</span>
    </div>
  `;

  fetch("/notifications/dropdown", {
    headers: {
      "Accept": "application/json",
      "X-Requested-With": "XMLHttpRequest"
    }
  })
  .then(r => r.json())
  .then(data => {
    renderDropdownNotifications(data.notifications, data.unread_count);
    updateNotificationBadge(data.unread_count);
  })
  .catch(() => {
    list.innerHTML = `<div class="notif-dropdown-error">Failed to load. <button onclick="loadNotificationsDropdown()">Retry</button></div>`;
  });
};

function renderDropdownNotifications(notifications, unreadCount) {
  const list = document.getElementById("notifDropdownList");
  const markAllBtn = document.getElementById("notifMarkAllBtn");

  if (markAllBtn) {
    markAllBtn.style.display = unreadCount > 0 ? "" : "none";
  }

  if (!notifications || notifications.length === 0) {
    list.innerHTML = `
      <div class="notif-dropdown-empty">
        <div class="notif-dropdown-empty-icon">
          <svg width="48" height="48" viewBox="0 0 24 24" fill="currentColor" opacity="0.3">
            <path d="M12 2C11.172 2 10.5 2.672 10.5 3.5v.44C8.261 4.553 7 6.315 7 8.5v4.5l-1.5 1.5v.75h13V14.5L17 13V8.5c0-2.185-1.261-3.947-3.5-4.56V3.5C13.5 2.672 12.828 2 12 2zm-3 16c0 1.657 1.343 3 3 3s3-1.343 3-3H9z"/>
          </svg>
        </div>
        <p>No notifications yet</p>
        <span>Interactions will appear here</span>
      </div>
    `;
    return;
  }

  list.innerHTML = notifications.map(n => buildDropdownItem(n)).join("");
}

function buildDropdownItem(n) {
  const avatarHtml = n.actor.avatar
    ? `<img src="${n.actor.avatar}" class="notif-dd-avatar" alt="${escapeHtml(n.actor.name)}">`
    : `<div class="notif-dd-avatar notif-dd-avatar-placeholder">${(n.actor.name || "?")[0].toUpperCase()}</div>`;

  const iconHtml = getNotifIconHtml(n.notification_type);
  const unreadClass = n.read ? "" : "unread";

  // Friend request inline actions in dropdown
  let friendActionsHtml = "";
  if (n.notification_type === "friend_request" && n.friendship_id && !n.friendship_accepted) {
    friendActionsHtml = `
      <div class="notif-dd-friend-actions" id="notif-dd-friend-${n.id}">
        <button class="notif-dd-btn-accept" onclick="ddAcceptFriend(${n.friendship_id}, ${n.id}, this)">Confirm</button>
        <button class="notif-dd-btn-decline" onclick="ddDeclineFriend(${n.friendship_id}, ${n.id}, this)">Delete</button>
      </div>`;
  }

  return `
    <div class="notif-dd-item ${unreadClass}" id="notif-dd-${n.id}" data-id="${n.id}">
      <a href="${n.target_url}" class="notif-dd-link" onclick="markDropdownItemRead(${n.id}, event)">
        <div class="notif-dd-avatar-wrap">
          ${avatarHtml}
          <div class="notif-dd-type-badge notif-type-${n.icon}">
            ${iconHtml}
          </div>
        </div>
        <div class="notif-dd-content">
          <p class="notif-dd-message">${escapeHtml(n.message)}</p>
          <span class="notif-dd-time">${escapeHtml(n.time_ago)} ago</span>
          ${friendActionsHtml}
        </div>
        ${!n.read ? '<span class="notif-dd-dot"></span>' : ''}
      </a>
    </div>
  `;
}

// ── Dropdown Friend Actions ───────────────────────────────────────────────
window.ddAcceptFriend = function(friendshipId, notifId, btn) {
  btn.disabled = true;
  btn.textContent = "...";
  fetch(`/friendships/${friendshipId}/accept`, {
    method: "PATCH",
    headers: {
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      "Accept": "application/json"
    }
  })
  .then(r => r.json())
  .then(() => {
    const actionsDiv = document.getElementById(`notif-dd-friend-${notifId}`);
    if (actionsDiv) actionsDiv.innerHTML = `<span class="notif-dd-accepted">✓ Friends now!</span>`;
    markDropdownItemRead(notifId, { target: document.getElementById(`notif-dd-${notifId}`) });
  })
  .catch(() => { btn.disabled = false; btn.textContent = "Confirm"; });
};

window.ddDeclineFriend = function(friendshipId, notifId, btn) {
  const item = document.getElementById(`notif-dd-${notifId}`);
  if (item) { item.style.opacity = "0"; item.style.transform = "translateX(20px)"; }
  setTimeout(() => {
    fetch(`/friendships/${friendshipId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
        "Accept": "application/json"
      }
    }).then(() => { if (item) item.remove(); });
  }, 250);
};

function prependNotificationToDropdown(notification, list) {
  const html = buildDropdownItem({
    ...notification,
    time_ago: "Just now",
    target_url: "#"
  });
  list.insertAdjacentHTML("afterbegin", html);

  // Animate the new item
  const newItem = list.firstElementChild;
  newItem.classList.add("notif-dd-item-new");
  setTimeout(() => newItem.classList.remove("notif-dd-item-new"), 600);
}

window.markDropdownItemRead = function(id, event) {
  // Prevent navigation only if clicking the friend action buttons
  if (event && event.target && event.target.closest('.notif-dd-friend-actions')) {
    event.preventDefault();
  }

  const item = document.getElementById(`notif-dd-${id}`);
  if (!item || !item.classList.contains("unread")) return;

  fetch(`/notifications/${id}/mark_read`, {
    method: "PATCH",
    headers: {
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      "Accept": "application/json"
    }
  })
  .then(r => r.json())
  .then(data => {
    item.classList.remove("unread");
    item.querySelector(".notif-dd-dot")?.remove();
    updateNotificationBadge(data.unread_count);
  });
};

window.markAllDropdownRead = function() {
  const btn = document.getElementById("notifMarkAllBtn");
  if (btn) btn.disabled = true;

  fetch("/notifications/mark_all_read", {
    method: "PATCH",
    headers: {
      "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content,
      "Accept": "application/json"
    }
  })
  .then(r => r.json())
  .then(() => {
    document.querySelectorAll(".notif-dd-item.unread").forEach(el => {
      el.classList.remove("unread");
      el.querySelector(".notif-dd-dot")?.remove();
    });
    updateNotificationBadge(0);
    if (btn) btn.style.display = "none";
  });
};

// ── Icon HTML helper ──────────────────────────────────────────────────────────
function getNotifIconHtml(type) {
  const icons = {
    like: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>`,
    comment: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M21.99 4c0-1.1-.89-2-1.99-2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4-.01-18z"/></svg>`,
    reply: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M10 9V5l-7 7 7 7v-4.1c5 0 8.5 1.6 11 5.1-1-5-4-10-11-11z"/></svg>`,
    friend: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M15 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm-9-2V7H4v3H1v2h3v3h2v-3h3v-2H6zm9 4c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg>`,
    share: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M18 16.08c-.76 0-1.44.3-1.96.77L8.91 12.7c.05-.23.09-.46.09-.7s-.04-.47-.09-.7l7.05-4.11c.54.5 1.25.81 2.04.81 1.66 0 3-1.34 3-3s-1.34-3-3-3-3 1.34-3 3c0 .24.04.47.09.7L8.04 9.81C7.5 9.31 6.79 9 6 9c-1.66 0-3 1.34-3 3s1.34 3 3 3c.79 0 1.5-.31 2.04-.81l7.12 4.16c-.05.21-.08.43-.08.65 0 1.61 1.31 2.92 2.92 2.92 1.61 0 2.92-1.31 2.92-2.92s-1.31-2.92-2.92-2.92z"/></svg>`,
    mention: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C6.48 2 2 6.48 2 12s4.48 10 10 10h5v-2h-5c-4.34 0-8-3.66-8-8s3.66-8 8-8 8 3.66 8 8v1.43c0 .79-.71 1.57-1.5 1.57s-1.5-.78-1.5-1.57V12c0-2.76-2.24-5-5-5s-5 2.24-5 5 2.24 5 5 5c1.38 0 2.64-.56 3.54-1.47.65.89 1.77 1.47 2.96 1.47 1.97 0 3.5-1.6 3.5-3.57V12c0-5.52-4.48-10-10-10zm0 13c-1.66 0-3-1.34-3-3s1.34-3 3-3 3 1.34 3 3-1.34 3-3 3z"/></svg>`,
    bell: `<svg width="12" height="12" viewBox="0 0 24 24" fill="currentColor"><path d="M12 2C11.172 2 10.5 2.672 10.5 3.5v.44C8.261 4.553 7 6.315 7 8.5v4.5l-1.5 1.5v.75h13V14.5L17 13V8.5c0-2.185-1.261-3.947-3.5-4.56V3.5C13.5 2.672 12.828 2 12 2zm-3 16c0 1.657 1.343 3 3 3s3-1.343 3-3H9z"/></svg>`
  };
  return icons[type] || icons.bell;
}

function escapeHtml(str) {
  if (!str) return "";
  return str.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

// ── Init ──────────────────────────────────────────────────────────────────────
document.addEventListener("DOMContentLoaded", () => {
  // Close dropdown when clicking outside
  document.addEventListener("click", (e) => {
    const dropdown = document.getElementById("notifDropdown");
    if (dropdown &&
        !e.target.closest(".fb-notification-btn") &&
        !e.target.closest("#notifDropdown")) {
      dropdown.classList.remove("show");
    }
  });
});

// Export and auto-init
const notificationChannel = new NotificationChannel();
export default notificationChannel;
