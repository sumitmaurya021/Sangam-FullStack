/**
 * Premium Header 2026 - JavaScript Module
 * Handles all interactive behaviors for the redesigned header
 */

class PremiumHeader {
  constructor() {
    const headerEl = document.getElementById('premiumHeader');
    if (!headerEl || headerEl.dataset.headerInitialized) {
      return;
    }
    headerEl.dataset.headerInitialized = 'true';
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

  // ==================== AI SEARCH & COMMAND PALETTE ====================

  initSearch() {
    const desktopInput = document.getElementById('headerSearchInput');
    const mobileInput = document.getElementById('mobileSearchInput');
    const mobileSearchToggle = document.getElementById('mobileSearchToggle');
    const searchModal = document.getElementById('aiSearchModal');
    const modalInput = document.getElementById('aiSearchInput');
    const closeBtn = document.getElementById('aiSearchCloseBtn');
    const tabs = document.querySelectorAll('.ai-search-tab');
    const suggestionsPane = document.getElementById('aiSearchSuggestions');
    const livePane = document.getElementById('aiLiveResultsPane');
    const copilotPane = document.getElementById('aiCopilotPane');
    const suggestItems = document.querySelectorAll('.ai-suggest-item');
    
    let liveSearchTimeout;
    let currentTab = 'live'; // 'live' or 'ai'

    // Open Modal Function
    const openModal = (initialValue = '') => {
      if (!searchModal) return;
      searchModal.classList.add('is-active');
      document.body.style.overflow = 'hidden';
      
      if (modalInput) {
        modalInput.value = initialValue;
        setTimeout(() => modalInput.focus(), 150);
        triggerSearch();
      }
    };

    // Close Modal Function
    const closeModal = () => {
      if (!searchModal) return;
      searchModal.classList.remove('is-active');
      document.body.style.overflow = '';
      if (modalInput) modalInput.value = '';
      if (desktopInput) desktopInput.value = '';
      resetModalState();
    };

    const resetModalState = () => {
      // Reset tabs to default (live)
      switchTab('live');
      
      // Clear search panes
      const liveResults = document.getElementById('aiLiveResultsCategories');
      if (liveResults) liveResults.innerHTML = '';
      
      const aiAnswer = document.getElementById('aiCopilotAnswer');
      if (aiAnswer) aiAnswer.innerHTML = '';
      
      const aiCards = document.getElementById('aiCopilotCardsGrid');
      if (aiCards) aiCards.innerHTML = '';
      
      document.getElementById('aiCopilotCardsSection').style.display = 'none';
      document.getElementById('aiCopilotLoader').style.display = 'none';
    };

    // Switch Search Tabs
    const switchTab = (tabName) => {
      currentTab = tabName;
      tabs.forEach(t => {
        if (t.dataset.searchTab === tabName) {
          t.classList.add('active');
        } else {
          t.classList.remove('active');
        }
      });

      if (tabName === 'live') {
        livePane.style.display = 'block';
        copilotPane.style.display = 'none';
        suggestionsPane.style.display = modalInput?.value.trim().length < 2 ? 'block' : 'none';
      } else {
        livePane.style.display = 'none';
        copilotPane.style.display = 'block';
        suggestionsPane.style.display = 'none';
      }
    };

    // Trigger Search Routing
    const triggerSearch = () => {
      const query = modalInput?.value.trim() || '';
      
      if (query.length < 2) {
        if (currentTab === 'live') {
          suggestionsPane.style.display = 'block';
          livePane.style.display = 'none';
        }
        return;
      }

      suggestionsPane.style.display = 'none';

      if (currentTab === 'live') {
        livePane.style.display = 'block';
        clearTimeout(liveSearchTimeout);
        liveSearchTimeout = setTimeout(() => {
          fetchLiveResults(query);
        }, 250);
      }
    };

    // Listeners for triggers
    if (desktopInput) {
      desktopInput.addEventListener('focus', (e) => {
        e.preventDefault();
        desktopInput.blur();
        openModal();
      });
      desktopInput.addEventListener('click', (e) => {
        e.preventDefault();
        desktopInput.blur();
        openModal();
      });
    }

    if (mobileSearchToggle) {
      mobileSearchToggle.addEventListener('click', (e) => {
        e.preventDefault();
        openModal();
      });
    }

    if (mobileInput) {
      mobileInput.addEventListener('focus', (e) => {
        e.preventDefault();
        mobileInput.blur();
        openModal();
      });
    }

    // Modal close listeners
    if (closeBtn) {
      closeBtn.addEventListener('click', closeModal);
    }

    if (searchModal) {
      searchModal.addEventListener('click', (e) => {
        if (e.target === searchModal) {
          closeModal();
        }
      });
    }

    // Global keyboard shortcuts (Ctrl+K or Cmd+K to open/close)
    window.addEventListener('keydown', (e) => {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        if (searchModal?.classList.contains('is-active')) {
          closeModal();
        } else {
          openModal();
        }
      }
      if (e.key === 'Escape' && searchModal?.classList.contains('is-active')) {
        e.preventDefault();
        closeModal();
      }
    });

    // Modal Input Listeners
    if (modalInput) {
      modalInput.addEventListener('input', triggerSearch);
      
      modalInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter') {
          e.preventDefault();
          const query = modalInput.value.trim();
          if (query.length >= 2) {
            if (currentTab !== 'ai') {
              switchTab('ai');
            }
            triggerAiSearch(query);
          }
        }
      });
    }

    // Tab switcher click listeners
    tabs.forEach(tab => {
      tab.addEventListener('click', () => {
        switchTab(tab.dataset.searchTab);
        triggerSearch();
        if (currentTab === 'ai' && modalInput?.value.trim().length >= 2) {
          triggerAiSearch(modalInput.value.trim());
        }
      });
    });

    // Suggestions Click
    suggestItems.forEach(item => {
      item.addEventListener('click', () => {
        const query = item.dataset.suggestQuery;
        switchTab('ai');
        if (modalInput) modalInput.value = query;
        triggerAiSearch(query);
      });
    });

    // Live Search API Call
    const fetchLiveResults = (query) => {
      const container = document.getElementById('aiLiveResultsCategories');
      if (!container) return;

      container.innerHTML = `
        <div class="ai-results-loading">
          <div class="premium-spinner"></div>
          <span>Searching Sangam database...</span>
        </div>
      `;

      fetch(`/search.json?q=${encodeURIComponent(query)}`)
        .then(res => res.json())
        .then(data => {
          this.renderLiveResults(data, query, container);
        })
        .catch(err => {
          console.error('Live search error:', err);
          container.innerHTML = `
            <div class="ai-search-error">
              <p>Search failed. Please try again.</p>
            </div>
          `;
        });
    };

    // AI Search API Call
    const triggerAiSearch = (query) => {
      const loader = document.getElementById('aiCopilotLoader');
      const answerContainer = document.getElementById('aiCopilotAnswer');
      const cardsGrid = document.getElementById('aiCopilotCardsGrid');
      const cardsSection = document.getElementById('aiCopilotCardsSection');

      if (loader) loader.style.display = 'flex';
      if (answerContainer) answerContainer.innerHTML = '';
      if (cardsSection) cardsSection.style.display = 'none';
      if (cardsGrid) cardsGrid.innerHTML = '';

      fetch('/api/ai/search', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content
        },
        body: JSON.stringify({ query: query })
      })
      .then(res => res.json())
      .then(data => {
        if (loader) loader.style.display = 'none';
        
        if (data.error) {
          if (answerContainer) {
            answerContainer.innerHTML = `<p class="ai-error-text">⚠️ ${this.escapeHtml(data.error)}</p>`;
          }
          return;
        }

        // 1. Render typewriter response
        if (answerContainer && data.answer) {
          this.typewriterEffect(answerContainer, data.answer, () => {
            // Callback: Fade in card previews
            renderResultCards(data.results);
          });
        }
      })
      .catch(err => {
        console.error('AI search fetch error:', err);
        if (loader) loader.style.display = 'none';
        if (answerContainer) {
          answerContainer.innerHTML = `<p class="ai-error-text">⚠️ AI search is currently unavailable. Please try again later.</p>`;
        }
      });
    };

    // Render Preview Cards Grid
    const renderResultCards = (results) => {
      if (!results) return;

      const cardsGrid = document.getElementById('aiCopilotCardsGrid');
      const cardsSection = document.getElementById('aiCopilotCardsSection');
      if (!cardsGrid || !cardsSection) return;

      let hasCards = false;
      let html = '';

      const keys = ['users', 'posts', 'groups', 'events', 'articles', 'listings'];
      keys.forEach(key => {
        const items = results[key] || [];
        items.forEach(item => {
          hasCards = true;
          html += this.renderCard(key, item);
        });
      });

      if (hasCards) {
        cardsGrid.innerHTML = html;
        cardsSection.style.display = 'block';
        cardsSection.classList.add('fade-in');
        
        // Auto scroll to make cards visible
        const contentEl = document.querySelector('.ai-search-content');
        if (contentEl) {
          setTimeout(() => {
            contentEl.scrollTop = contentEl.scrollHeight;
          }, 100);
        }
      }
    };
  }

  // ==================== RENDERING METHODS ====================

  renderLiveResults(data, query, container) {
    if (!container) return;
    
    let hasResults = false;
    let html = '';

    const categories = [
      { key: 'users', title: 'People', icon: '👤', render: u => this.renderLiveUser(u) },
      { key: 'posts', title: 'Posts', icon: '📝', render: p => this.renderLivePost(p) },
      { key: 'groups', title: 'Groups', icon: '👥', render: g => this.renderLiveGroup(g) },
      { key: 'events', title: 'Events', icon: '📅', render: e => this.renderLiveEvent(e) },
      { key: 'hashtags', title: 'Hashtags', icon: '#', render: h => this.renderLiveHashtag(h) }
    ];

    categories.forEach(cat => {
      const items = data[cat.key] || [];
      if (items.length > 0) {
        hasResults = true;
        html += `
          <div class="ai-result-section">
            <h4 class="ai-result-section-title">${cat.icon} ${cat.title}</h4>
            <div class="ai-result-list">
              ${items.map(item => cat.render(item)).join('')}
            </div>
          </div>
        `;
      }
    });

    if (!hasResults) {
      container.innerHTML = `
        <div class="ai-search-empty-state">
          <div class="ai-empty-icon">🔍</div>
          <h4>No results for "${this.escapeHtml(query)}"</h4>
          <p>Try searching for a different keyword or check spelling.</p>
        </div>
      `;
    } else {
      container.innerHTML = html;
    }
  }

  renderLiveUser(user) {
    const avatar = user.avatar 
      ? `<img src="${user.avatar}" alt="${this.escapeHtml(user.name)}" class="ai-live-avatar" />`
      : `<div class="ai-live-avatar-placeholder">${(user.name || '?')[0].toUpperCase()}</div>`;
    
    return `
      <a href="${user.profile_url}" class="ai-live-result-item">
        <div class="ai-live-icon-wrap user-badge user-icon-animated">
          ${avatar}
        </div>
        <div class="ai-live-result-info">
          <span class="ai-live-result-title">${this.escapeHtml(user.name)}</span>
        </div>
        <span class="ai-live-result-tag user-tag">Person</span>
      </a>
    `;
  }

  renderLivePost(post) {
    return `
      <a href="${post.post_url || `/posts/${post.id}`}" class="ai-live-result-item">
        <div class="ai-live-icon-wrap post-badge">
          <svg class="ai-card-svg post-line-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
            <polyline points="14 2 14 8 20 8"></polyline>
            <line x1="16" y1="13" x2="8" y2="13"></line>
            <line x1="16" y1="17" x2="8" y2="17"></line>
          </svg>
        </div>
        <div class="ai-live-result-info">
          <span class="ai-live-result-title">Post by ${this.escapeHtml(post.user)}</span>
          <span class="ai-live-result-subtitle">${this.escapeHtml(post.content)}</span>
        </div>
        <span class="ai-live-result-tag post-tag">Post</span>
      </a>
    `;
  }

  renderLiveGroup(group) {
    const url = group.group_url || `/groups/${group.id}`;
    return `
      <a href="${url}" class="ai-live-result-item">
        <div class="ai-live-icon-wrap group-badge">
          <svg class="ai-card-svg group-avatar-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
            <circle cx="9" cy="7" r="4"></circle>
            <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
            <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
          </svg>
        </div>
        <div class="ai-live-result-info">
          <span class="ai-live-result-title">${this.escapeHtml(group.name)}</span>
          <span class="ai-live-result-subtitle">${group.members_count} members</span>
        </div>
        <span class="ai-live-result-tag group-tag">Group</span>
      </a>
    `;
  }

  renderLiveEvent(event) {
    const url = event.event_url || `/events/${event.id}`;
    return `
      <a href="${url}" class="ai-live-result-item">
        <div class="ai-live-icon-wrap event-badge">
          <svg class="ai-card-svg event-calendar-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
            <line x1="16" y1="2" x2="16" y2="6"></line>
            <line x1="8" y1="2" x2="8" y2="6"></line>
            <line x1="3" y1="10" x2="21" y2="10"></line>
          </svg>
        </div>
        <div class="ai-live-result-info">
          <span class="ai-live-result-title">${this.escapeHtml(event.title)}</span>
          <span class="ai-live-result-subtitle">${event.starts_at}</span>
        </div>
        <span class="ai-live-result-tag event-tag">Event</span>
      </a>
    `;
  }

  renderLiveHashtag(hashtag) {
    return `
      <a href="/hashtag/${hashtag.name.replace('#', '')}" class="ai-live-result-item">
        <div class="ai-live-icon-wrap hashtag-badge">
          <svg class="ai-card-svg listing-tag-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"></path>
            <line x1="7" y1="7" x2="7.01" y2="7"></line>
          </svg>
        </div>
        <div class="ai-live-result-info">
          <span class="ai-live-result-title">${this.escapeHtml(hashtag.name)}</span>
          <span class="ai-live-result-subtitle">${hashtag.posts_count} posts</span>
        </div>
        <span class="ai-live-result-tag hashtag-tag">Tag</span>
      </a>
    `;
  }

  // AI Referenced Card Renderers
  renderCard(type, item) {
    if (type === 'users') {
      const avatar = item.avatar 
        ? `<img src="${item.avatar}" alt="${this.escapeHtml(item.name)}" class="ai-card-avatar" />`
        : `<div class="ai-card-avatar-placeholder">${(item.name || '?')[0].toUpperCase()}</div>`;
      
      return `
        <a href="${item.profile_url}" class="ai-resource-card">
          <div class="ai-card-header">
            <div class="ai-card-icon-wrap user-badge user-icon-animated">${avatar}</div>
            <div class="ai-card-meta">
              <span class="ai-card-badge user-badge">Person</span>
            </div>
          </div>
          <div class="ai-card-body">
            <h4 class="ai-card-title">${this.escapeHtml(item.name)}</h4>
            <p class="ai-card-desc">${item.mutual_friends_count > 0 ? `${item.mutual_friends_count} mutual friend${item.mutual_friends_count > 1 ? 's' : ''}` : 'View profile'}</p>
          </div>
        </a>
      `;
    } else if (type === 'posts') {
      return `
        <a href="${item.post_url}" class="ai-resource-card">
          <div class="ai-card-header">
            <div class="ai-card-icon-wrap post-badge">
              <svg class="ai-card-svg post-line-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"></path>
                <polyline points="14 2 14 8 20 8"></polyline>
                <line x1="16" y1="13" x2="8" y2="13"></line>
                <line x1="16" y1="17" x2="8" y2="17"></line>
              </svg>
            </div>
            <div class="ai-card-meta">
              <span class="ai-card-badge post-badge">Post</span>
              <span class="ai-card-time">${item.created_at}</span>
            </div>
          </div>
          <div class="ai-card-body">
            <h4 class="ai-card-title">Post by ${this.escapeHtml(item.user)}</h4>
            <p class="ai-card-desc">"${this.escapeHtml(item.content)}"</p>
          </div>
        </a>
      `;
    } else if (type === 'groups') {
      return `
        <a href="${item.group_url}" class="ai-resource-card">
          <div class="ai-card-header">
            <div class="ai-card-icon-wrap group-badge">
              <svg class="ai-card-svg group-avatar-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"></path>
                <circle cx="9" cy="7" r="4"></circle>
                <path d="M23 21v-2a4 4 0 0 0-3-3.87"></path>
                <path d="M16 3.13a4 4 0 0 1 0 7.75"></path>
              </svg>
            </div>
            <div class="ai-card-meta">
              <span class="ai-card-badge group-badge">Group</span>
              <span class="ai-card-count">${item.members_count} members</span>
            </div>
          </div>
          <div class="ai-card-body">
            <h4 class="ai-card-title">${this.escapeHtml(item.name)}</h4>
            <p class="ai-card-desc">${this.escapeHtml(item.description)}</p>
          </div>
        </a>
      `;
    } else if (type === 'events') {
      return `
        <a href="${item.event_url}" class="ai-resource-card">
          <div class="ai-card-header">
            <div class="ai-card-icon-wrap event-badge">
              <svg class="ai-card-svg event-calendar-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect x="3" y="4" width="18" height="18" rx="2" ry="2"></rect>
                <line x1="16" y1="2" x2="16" y2="6"></line>
                <line x1="8" y1="2" x2="8" y2="6"></line>
                <line x1="3" y1="10" x2="21" y2="10"></line>
              </svg>
            </div>
            <div class="ai-card-meta">
              <span class="ai-card-badge event-badge">Event</span>
            </div>
          </div>
          <div class="ai-card-body">
            <h4 class="ai-card-title">${this.escapeHtml(item.title)}</h4>
            <p class="ai-card-desc">${item.starts_at}</p>
          </div>
        </a>
      `;
    } else if (type === 'articles') {
      return `
        <a href="${item.article_url}" class="ai-resource-card">
          <div class="ai-card-header">
            <div class="ai-card-icon-wrap article-badge">
              <svg class="ai-card-svg article-page-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M4 4h16c1.1 0 2 .9 2 2v12c0 1.1-.9 2-2 2H4c-1.1 0-2-.9-2-2V6c0-1.1.9-2 2-2z"></path>
                <path d="M16 8h2v2h-2zm0 4h2v2h-2zM6 8h6v6H6z"></path>
              </svg>
            </div>
            <div class="ai-card-meta">
              <span class="ai-card-badge article-badge">Article</span>
              <span class="ai-card-count">${item.views_count} views</span>
            </div>
          </div>
          <div class="ai-card-body">
            <h4 class="ai-card-title">${this.escapeHtml(item.title)}</h4>
            <p class="ai-card-desc">By ${this.escapeHtml(item.user)}</p>
          </div>
        </a>
      `;
    } else if (type === 'listings') {
      const formattedPrice = item.price && parseFloat(item.price) > 0 ? `$${parseFloat(item.price).toFixed(2)}` : 'Free';
      return `
        <a href="${item.listing_url}" class="ai-resource-card">
          <div class="ai-card-header">
            <div class="ai-card-icon-wrap market-badge">
              <svg class="ai-card-svg listing-tag-animated" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M20.59 13.41l-7.17 7.17a2 2 0 0 1-2.83 0L2 12V2h10l8.59 8.59a2 2 0 0 1 0 2.82z"></path>
                <line x1="7" y1="7" x2="7.01" y2="7"></line>
              </svg>
            </div>
            <div class="ai-card-meta">
              <span class="ai-card-badge market-badge">Listing</span>
              <span class="ai-card-price">${formattedPrice}</span>
            </div>
          </div>
          <div class="ai-card-body">
            <h4 class="ai-card-title">${this.escapeHtml(item.title)}</h4>
            <p class="ai-card-desc">Category: ${this.escapeHtml(item.category)} • ${this.escapeHtml(item.condition)}</p>
          </div>
        </a>
      `;
    }
    return '';
  }

  // Typewriter effect to write text gradually
  typewriterEffect(container, rawText, callback) {
    container.innerHTML = '';
    let index = 0;
    
    const timer = setInterval(() => {
      if (index < rawText.length) {
        container.innerHTML = this.formatMarkdown(rawText.substring(0, index + 1)) + '<span class="ai-cursor">|</span>';
        index++;
        
        const contentEl = document.querySelector('.ai-search-content');
        if (contentEl) {
          contentEl.scrollTop = contentEl.scrollHeight;
        }
      } else {
        clearInterval(timer);
        container.innerHTML = this.formatMarkdown(rawText);
        if (callback) callback();
      }
    }, 8); // Speedy character animation
  }

  // Safe markdown tags formatter
  formatMarkdown(text) {
    if (!text) return '';
    let formatted = text;
    
    // Escape HTML to prevent injection, allowing only structured markdown conversions
    formatted = this.escapeHtml(formatted);
    
    // Bold parsing
    formatted = formatted.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>');
    formatted = formatted.replace(/__(.*?)__/g, '<strong>$1</strong>');
    
    // Relative markdown link parsing
    formatted = formatted.replace(/\[(.*?)\]\((.*?)\)/g, '<a href="$2" class="ai-md-link">$1</a>');
    
    // Newline mapping
    formatted = formatted.replace(/\n/g, '<br/>');
    
    return formatted;
  }

  escapeHtml(text) {
    if (!text) return '';
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
    if (window.premiumHeaderGlobalListenersInitialized) return;
    window.premiumHeaderGlobalListenersInitialized = true;

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
        document.getElementById('searchDropdown')?.classList.remove('is-active');
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

// Initialize on DOM ready and after Turbo navigations
const initPremiumHeader = () => {
  new PremiumHeader();
};

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initPremiumHeader);
} else {
  initPremiumHeader();
}

document.addEventListener('turbo:load', initPremiumHeader);

// Clean up state before caching to handle Turbo preview visits correctly
document.addEventListener('turbo:before-cache', () => {
  // Close all active dropdowns
  document.querySelectorAll('.premium-dropdown').forEach(dropdown => {
    dropdown.classList.remove('is-active');
  });
  document.querySelectorAll('[aria-expanded]').forEach(btn => {
    btn.setAttribute('aria-expanded', 'false');
  });
  
  // Remove initialization marker so that it gets re-initialized on restore/preview
  const headerEl = document.getElementById('premiumHeader');
  if (headerEl) {
    delete headerEl.dataset.headerInitialized;
  }
});

// Export for potential module usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = PremiumHeader;
}
