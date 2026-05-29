// GIF Picker — uses Giphy API
// API key is read from <meta name="giphy-api-key"> set by Rails from ENV['GIPHY_API_KEY']
// Get your free key at: https://developers.giphy.com

const GIPHY_BASE = "https://api.giphy.com/v1/gifs";

export class GifPicker {
  constructor(chatApp) {
    this.chatApp     = chatApp;
    this.modal       = document.getElementById("gifPickerModal");
    this.grid        = document.getElementById("gifGrid");
    this.searchInput = document.getElementById("gifSearchInput");
    this.searchTimer = null;

    // Read API key from meta tag (populated by Rails from ENV['GIPHY_API_KEY'])
    const key = document.querySelector('meta[name="giphy-api-key"]')?.content;
    this.apiKey = (key && key.trim() !== '') ? key.trim() : null;

    this._setupSearch();
    this._setupOutsideClick();
  }

  // ─── Public ────────────────────────────────────────────────────────────────

  toggle() {
    if (!this.modal) return;
    const isHidden = this.modal.style.display === "none" || !this.modal.style.display;
    if (isHidden) {
      this.modal.style.display = "flex";
      this._loadTrending();
      this.searchInput?.focus();
    } else {
      this.hide();
    }
  }

  hide() {
    if (this.modal) this.modal.style.display = "none";
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  _setupSearch() {
    this.searchInput?.addEventListener("input", (e) => {
      clearTimeout(this.searchTimer);
      const q = e.target.value.trim();
      this.searchTimer = setTimeout(() => {
        q ? this._searchGifs(q) : this._loadTrending();
      }, 400);
    });
  }

  _setupOutsideClick() {
    document.addEventListener("click", (e) => {
      if (this.modal &&
          !e.target.closest("#gifPickerModal") &&
          !e.target.closest("#gifBtn")) {
        this.hide();
      }
    });
  }

  async _loadTrending() {
    if (!this.grid) return;
    if (!this.apiKey) { this._renderFallback(); return; }

    this.grid.innerHTML = '<div class="gif-loading">Loading trending GIFs...</div>';
    try {
      const url  = `${GIPHY_BASE}/trending?api_key=${this.apiKey}&limit=20&rating=g`;
      const res  = await fetch(url);
      const data = await res.json();
      this._renderGifs(data.data || []);
    } catch (e) {
      console.error("[GifPicker] Trending load failed:", e);
      this._renderFallback();
    }
  }

  async _searchGifs(query) {
    if (!this.grid) return;
    if (!this.apiKey) { this._renderFallback(); return; }

    this.grid.innerHTML = '<div class="gif-loading">Searching...</div>';
    try {
      const url  = `${GIPHY_BASE}/search?api_key=${this.apiKey}&q=${encodeURIComponent(query)}&limit=20&rating=g`;
      const res  = await fetch(url);
      const data = await res.json();
      this._renderGifs(data.data || []);
    } catch (e) {
      console.error("[GifPicker] Search failed:", e);
      this._renderFallback();
    }
  }

  _renderGifs(gifs) {
    if (!this.grid) return;

    if (!gifs.length) {
      this.grid.innerHTML = '<div class="gif-loading">No GIFs found 😕</div>';
      return;
    }

    this.grid.innerHTML = gifs.map(gif => {
      // Use downsized preview for grid, original for sending
      const preview = gif.images?.fixed_height_small?.url || gif.images?.downsized?.url;
      const full    = gif.images?.original?.url || gif.images?.downsized?.url;
      const title   = gif.title || "GIF";

      if (!preview || !full) return "";

      // Escape single quotes in URL for onclick
      const safeUrl = full.replace(/'/g, "\\'");

      return `
        <div class="gif-item" onclick="chatApp._sendGifFromUrl('${safeUrl}')" title="${title}">
          <img src="${preview}" alt="${title}" loading="lazy" class="gif-thumbnail">
        </div>`;
    }).join("");
  }

  _renderFallback() {
    if (!this.grid) return;

    const emojis = [
      { e: "😂", l: "Laughing"  }, { e: "❤️",  l: "Heart"    },
      { e: "👍", l: "Thumbs Up" }, { e: "🎉",  l: "Party"    },
      { e: "🔥", l: "Fire"      }, { e: "😍",  l: "Love"     },
      { e: "😭", l: "Crying"    }, { e: "🤣",  l: "ROFL"     },
      { e: "😊", l: "Smile"     }, { e: "🙏",  l: "Pray"     },
      { e: "💯", l: "100"       }, { e: "🥳",  l: "Celebrate"}
    ];

    this.grid.innerHTML = `
      <div class="gif-api-note">
        Add <strong>GIPHY_API_KEY</strong> in .env for real GIFs<br>
        <a href="https://developers.giphy.com" target="_blank" style="color:#0084ff;">
          Get free key →
        </a>
      </div>
      ${emojis.map(g => `
        <div class="gif-item gif-emoji-item" onclick="chatApp._sendTextAsMessage('${g.e}')">
          <span class="gif-emoji">${g.e}</span>
          <span class="gif-emoji-label">${g.l}</span>
        </div>`).join("")}`;
  }
}
