/**
 * Premium Header 2026 - JavaScript Module
 * Handles all interactive behaviors for the redesigned header
 */

class PremiumHeader {
  constructor() {
    this.init();
  }

  init() {
    this.initDropdowns();
    this.initMobileMenu();
    this.initMobileSearch();
    this.initSearch();
    this.initClickOutside();
    this.initNotifications();
    this.initDarkModeToggle();
  }

  // ==================== DROPDOWNS ====================

  initDropdowns() {
    // User menu
    const userBtn = document.getElementById('userMenuBtn');
    const userDropdown = document.getElementById('userDropdown');
    
    if (userBtn && userDropdown) {
      userBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.toggleDropdown(userBtn, userDropdown);
      });
    }

    // Notifications
    const notifBtn = document.getElementById('notificationsBtn');
    const notifDropdown = document.getElementById('notificationsDropdown');
    
    if (notifBtn && notifDropdown) {
      notifBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this.toggleDropdown(notifBtn, notifDropdown);
        
        // Load notifications if opening
        if (!notifDropdown.classList.contains('is-active')) {
          this.loadNotifications();
        }
      });
    }
  }

  toggleDropdown(button, dropdown) {
    const isActive = dropdown.classList.contains('is-active');
    
    // Close all dropdowns
    document.querySelectorAll('.premium-dropdown').forEach(d => {
      d.classList.remove('is-active');
    });
    
    // Reset all aria-expanded
    document.querySelectorAll('[aria-expanded]').forEach(btn => {
      btn.setAttribute('aria-expanded', 'false');
    });
    
    // Toggle current
    if (!isActive) {
      dropdown.classList.add('is-active');
      button.setAttribute('aria-expanded', 'true');
    }
  }

  // ==================== MOBILE MENU ====================

  initMobileMenu() {
    const menuToggle = document.getElementById('mobileMenuToggle');
    const menuClose = document.getElementById('mobileMenuClose');
    const menuOverlay = document.getElementById('mobileMenuOverlay');
    
    if (menuToggle && menuOverlay) {
      menuToggle.addEventListener('click', () => {
        menuOverlay.classList.add('is-active');
        document.body.style.overflow = 'hidden';
      });
    }
    
    if (menuClose && menuOverlay) {
      menuClose.addEventListener('click', () => {
        menuOverlay.classList.remove('is-active');
        document.body.style.overflow = '';
      });
    }
  }

  // ==================== MOBILE SEARCH ====================

  initMobileSearch() {
    const searchToggle = document.getElementById('mobileSearchToggle');
    const searchClose = document.getElementById('mobileSearchClose');
    const searchOverlay = document.getElementById('mobileSearchOverlay');
    const mobileInput = document.getElementById('mobileSearchInput');
    
    if (searchToggle && searchOverlay) {
      searchToggle.addEventListener('click', () => {
        searchOverlay.classList.add('is-active');
        document.body.style.overflow = 'hidden';
        setTimeout(() => mobileInput?.focus(), 300);
      });
    }
    
    if (searchClose && searchOverlay) {
      searchClose.addEventListener('click', () => {
        searchOverlay.classList.remove('is-active');
        document.body.style.overflow = '';
        if (mobileInput) mobileInput.value = '';
      });
    }
  }

  // ==================== SEARCH ====================

  initSearch() {
    const desktopInput = document.getElementById('headerSearchInput');
    const mobileInput = document.getElementById('mobileSearchInput');
    let searchTimeout;

    const handleSearch = (input, resultsContainer) => {
      clearTimeout(searchTimeout);
      const query = input.value.trim();
      
      if (query.length < 2) {
        this.closeSearchDropdown();
        return;
      }
      
      this.showSearchLoading(resultsContainer);
      
      searchTimeout = setTimeout(() => {
        this.fetchSearchResults(query, resultsContainer);
      }, 300);
    };

    if (desktopInput) {
      desktopInput.addEventListener('input', () => {
        const dropdown = document.getElementById('searchDropdown');
        handleSearch(desktopInput, document.getElementById('searchResults'));
      });
      
      desktopInput.addEventListener('focus', () => {
        if (desktopInput.value.trim().length >= 2) {
          document.getElementById('searchDropdown')?.classList.add('is-active');
        }
      });
    }

    if (mobileInput) {
      mobileInput.addEventListener('input', () => {
        handleSearch(mobileInput, document.getElementById('mobileSearchResults'));
      });
    }
  }

  showSearchLoading(container) {
    if (!container) return;
    container.innerHTML = `
      <div class="premium-dropdown__loading">
        <div class="premium-spinner"></div>
        <span>Searching...</span>
      </div>
    `;
  }

  fetchSearchResults(query, container) {
    if (!container) return;
    
    fetch(`/profiles/search?q=${encodeURIComponent(query)}`, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(res => res.json())
    .then(users => {
      this.renderSearchResults(users, query, container);
    })
    .catch(err => {
      console.error('Search error:', err);
      container.innerHTML = `
        <div class="premium-dropdown__loading">
          <p>Search error. Please try again.</p>
        </div>
      `;
    });
  }

  renderSearchResults(users, query, container) {
    if (!container) return;
    
    // Show dropdown for desktop search
    document.getElementById('searchDropdown')?.classList.add('is-active');
    
    if (users.length === 0) {
      container.innerHTML = `
        <div style="padding: 32px 20px; text-align: center; color: var(--text-tertiary);">
          <div style="font-size: 48px; margin-bottom: 12px; opacity: 0.6;">🔍</div>
          <p style="margin: 6px 0; font-size: 14px; font-weight: 500;">No results for "<strong>${this.escapeHtml(query)}</strong>"</p>
          <p style="font-size: 12px; color: var(--text-tertiary);">Try a different name or email</p>
        </div>
      `;
      return;
    }
    
    container.innerHTML = `
      <div style="padding: 8px;">
        <div style="padding: 8px 12px; font-size: 12px; font-weight: 800; color: #667eea; text-transform: uppercase; letter-spacing: 1px;">
          People
        </div>
        ${users.map(user => this.renderUserResult(user)).join('')}
      </div>
    `;
  }

  renderUserResult(user) {
    const avatar = user.avatar 
      ? `<img src="${user.avatar}" alt="${this.escapeHtml(user.name)}" style="width: 48px; height: 48px; border-radius: 50%; object-fit: cover; border: 2px solid rgba(102, 126, 234, 0.1);" />`
      : `<div style="width: 48px; height: 48px; border-radius: 50%; background: linear-gradient(135deg, #667eea, #764ba2); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 700; font-size: 18px;">${(user.name || '?')[0].toUpperCase()}</div>`;
    
    const online = user.online ? '<span style="position: absolute; bottom: 2px; right: 2px; width: 12px; height: 12px; border-radius: 50%; background: #31a24c; border: 2px solid #fff;"></span>' : '';
    
    return `
      <a href="${user.profile_url}" style="display: flex; align-items: center; gap: 12px; padding: 10px 12px; text-decoration: none; color: var(--text-primary); border-radius: 12px; transition: all 0.2s; position: relative;">
        <div style="position: relative; flex-shrink: 0;">
          ${avatar}
          ${online}
        </div>
        <div style="flex: 1; min-width: 0;">
          <div style="font-size: 15px; font-weight: 700; color: var(--text-primary);">${this.escapeHtml(user.name)}</div>
          <div style="font-size: 12px; color: var(--text-tertiary);">${user.mutual_friends_count > 0 ? `${user.mutual_friends_count} mutual friend${user.mutual_friends_count > 1 ? 's' : ''}` : this.escapeHtml(user.email)}</div>
        </div>
      </a>
    `;
  }

  closeSearchDropdown() {
    document.getElementById('searchDropdown')?.classList.remove('is-active');
  }

  escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ==================== NOTIFICATIONS ====================

  initNotifications() {
    const markAllBtn = document.getElementById('markAllReadBtn');
    
    if (markAllBtn) {
      markAllBtn.addEventListener('click', () => {
        this.markAllNotificationsRead();
      });
    }
  }

  loadNotifications() {
    const container = document.getElementById('notificationsList');
    if (!container) return;
    
    // Show loading state
    container.innerHTML = `
      <div class="premium-dropdown__loading">
        <div class="premium-spinner"></div>
        <span>Loading...</span>
      </div>
    `;
    
    // Fetch notifications (adjust URL to your actual endpoint)
    fetch('/notifications.json', {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(res => res.json())
    .then(notifications => {
      this.renderNotifications(notifications, container);
    })
    .catch(err => {
      console.error('Notifications error:', err);
      container.innerHTML = `
        <div class="premium-dropdown__loading">
          <p>Failed to load notifications</p>
        </div>
      `;
    });
  }

  renderNotifications(notifications, container) {
    if (notifications.length === 0) {
      container.innerHTML = `
        <div style="padding: 32px 20px; text-align: center; color: var(--text-tertiary);">
          <div style="font-size: 48px; margin-bottom: 12px; opacity: 0.6;">🔔</div>
          <p style="font-size: 14px; font-weight: 500;">No notifications yet</p>
        </div>
      `;
      return;
    }
    
    container.innerHTML = notifications.map(notif => `
      <div style="padding: 12px 16px; border-radius: 12px; transition: all 0.2s; ${notif.read ? '' : 'background: rgba(102, 126, 234, 0.05);'}">
        <div style="font-size: 14px; color: var(--text-primary); margin-bottom: 4px;">${notif.message}</div>
        <div style="font-size: 12px; color: var(--text-tertiary);">${notif.time}</div>
      </div>
    `).join('');
  }

  markAllNotificationsRead() {
    // Implement your mark all read logic here
    console.log('Mark all notifications as read');
    
    // Update badge
    const badge = document.getElementById('notifBadge');
    if (badge) {
      badge.style.display = 'none';
    }
  }

  // ==================== CLICK OUTSIDE ====================

  initClickOutside() {
    document.addEventListener('click', (e) => {
      // Close dropdowns when clicking outside
      if (!e.target.closest('.premium-dropdown') && !e.target.closest('[aria-expanded]')) {
        document.querySelectorAll('.premium-dropdown').forEach(dropdown => {
          dropdown.classList.remove('is-active');
        });
        
        document.querySelectorAll('[aria-expanded]').forEach(btn => {
          btn.setAttribute('aria-expanded', 'false');
        });
      }
      
      // Close search dropdown when clicking outside
      if (!e.target.closest('.premium-search') && !e.target.closest('.premium-search__dropdown')) {
        this.closeSearchDropdown();
      }
    });
    
    // Close mobile overlays on escape key
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') {
        // Close mobile menu
        const mobileMenu = document.getElementById('mobileMenuOverlay');
        if (mobileMenu?.classList.contains('is-active')) {
          mobileMenu.classList.remove('is-active');
          document.body.style.overflow = '';
        }
        
        // Close mobile search
        const mobileSearch = document.getElementById('mobileSearchOverlay');
        if (mobileSearch?.classList.contains('is-active')) {
          mobileSearch.classList.remove('is-active');
          document.body.style.overflow = '';
        }
        
        // Close dropdowns
        document.querySelectorAll('.premium-dropdown').forEach(dropdown => {
          dropdown.classList.remove('is-active');
        });
        
        document.querySelectorAll('[aria-expanded]').forEach(btn => {
          btn.setAttribute('aria-expanded', 'false');
        });
      }
    });
  }

  // ==================== DARK MODE TOGGLE ====================

  initDarkModeToggle() {
    // Desktop toggle
    const desktopCheckbox = document.getElementById('darkModeCheckbox');
    if (desktopCheckbox) {
      desktopCheckbox.addEventListener('change', () => {
        this.toggleDarkMode(desktopCheckbox.checked);
      });
    }

    // Mobile toggle
    const mobileCheckbox = document.getElementById('mobileDarkModeCheckbox');
    if (mobileCheckbox) {
      mobileCheckbox.addEventListener('change', () => {
        this.toggleDarkMode(mobileCheckbox.checked);
      });
    }
  }

  toggleDarkMode(isDark) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
    if (!csrfToken) return;

    // Immediate UI update for smooth transition
    document.documentElement.classList.toggle('dark-mode', isDark);
    document.body.classList.toggle('dark-mode', isDark);
    document.body.dataset.darkMode = isDark ? 'true' : 'false';

    // Update icons and labels on both toggles
    this.updateDarkModeUI(isDark);

    // Persist to server
    fetch('/profiles/toggle_dark_mode', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
      },
      body: JSON.stringify({ dark_mode: isDark })
    })
    .then(res => res.json())
    .then(data => {
      if (!data.success) {
        console.error('Dark mode toggle failed:', data);
        // Revert on error
        document.documentElement.classList.toggle('dark-mode', !isDark);
        document.body.classList.toggle('dark-mode', !isDark);
        document.body.dataset.darkMode = isDark ? 'false' : 'true';
        this.updateDarkModeUI(!isDark);
      }
    })
    .catch(err => {
      console.error('Dark mode toggle error:', err);
      // Revert on error
      document.documentElement.classList.toggle('dark-mode', !isDark);
      document.body.classList.toggle('dark-mode', !isDark);
      document.body.dataset.darkMode = isDark ? 'false' : 'true';
      this.updateDarkModeUI(!isDark);
    });
  }

  updateDarkModeUI(isDark) {
    // Desktop icon & label
    const desktopIcon = document.getElementById('darkModeIcon');
    const desktopLabel = document.getElementById('darkModeLabel');
    const desktopCheckbox = document.getElementById('darkModeCheckbox');

    if (desktopIcon) {
      desktopIcon.innerHTML = isDark
        ? `<circle cx="10" cy="10" r="3" fill="currentColor"/><path d="M10 1v2m0 14v2M4.22 4.22l1.42 1.42m8.72 8.72l1.42 1.42M1 10h2m14 0h2M4.22 15.78l1.42-1.42m8.72-8.72l1.42-1.42" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>`
        : `<path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"/>`;
    }

    if (desktopLabel) {
      desktopLabel.textContent = isDark ? 'Light Mode' : 'Dark Mode';
    }

    if (desktopCheckbox) {
      desktopCheckbox.checked = isDark;
    }

    // Mobile icon & label
    const mobileIcon = document.getElementById('mobileDarkModeIcon');
    const mobileLabel = document.getElementById('mobileDarkModeLabel');
    const mobileCheckbox = document.getElementById('mobileDarkModeCheckbox');

    if (mobileIcon) {
      mobileIcon.innerHTML = isDark
        ? `<circle cx="10" cy="10" r="3" fill="currentColor"/><path d="M10 1v2m0 14v2M4.22 4.22l1.42 1.42m8.72 8.72l1.42 1.42M1 10h2m14 0h2M4.22 15.78l1.42-1.42m8.72-8.72l1.42-1.42" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>`
        : `<path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"/>`;
    }

    if (mobileLabel) {
      mobileLabel.textContent = isDark ? 'Light Mode' : 'Dark Mode';
    }

    if (mobileCheckbox) {
      mobileCheckbox.checked = isDark;
    }
  }
}

// Initialize on DOM ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    new PremiumHeader();
  });
} else {
  new PremiumHeader();
}

// Export for potential module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = PremiumHeader;
}
