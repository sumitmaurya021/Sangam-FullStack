// ── Link Preview Auto-Fetcher ─────────────────────────────────────
// Detects URLs pasted into the post textarea → fetches OG meta → shows preview card
// Also populates hidden fields for server-side storage

(function () {
  const URL_REGEX = /https?:\/\/(www\.)?[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_+.~#?&/=]*)/gi;
  let debounceTimer = null;
  let lastFetchedUrl = null;

  function init() {
    const textarea = document.getElementById('new-post-form')
                  ?.querySelector('textarea[name="post[content]"]');
    if (!textarea) return;

    textarea.addEventListener('input', () => {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => checkForUrl(textarea.value), 800);
    });
  }

  function checkForUrl(text) {
    const matches = text.match(URL_REGEX);
    if (!matches || matches.length === 0) {
      removePreviews();
      return;
    }
    const url = matches[matches.length - 1]; // use the last URL
    if (url === lastFetchedUrl) return;
    lastFetchedUrl = url;
    fetchPreview(url);
  }

  async function fetchPreview(url) {
    const container = getOrCreatePreviewContainer();
    container.innerHTML = '<div class="link-preview-loading">🔗 Fetching preview...</div>';

    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
      const resp = await fetch(`/link_preview?url=${encodeURIComponent(url)}`, {
        headers: { 'X-CSRF-Token': csrfToken || '' }
      });
      if (!resp.ok) { container.innerHTML = ''; return; }

      const data = await resp.json();
      if (!data.title) { container.innerHTML = ''; return; }

      renderPreview(container, data);
      populateHiddenFields(data);
    } catch (e) {
      container.innerHTML = '';
    }
  }

  function renderPreview(container, data) {
    container.innerHTML = `
      <div class="link-preview-card">
        <button type="button" class="link-preview-close" onclick="removeLinkPreview()" aria-label="Remove preview">✕</button>
        ${data.image ? `<img class="link-preview-img" src="${escapeHtml(data.image)}" alt="Preview" onerror="this.style.display='none'">` : ''}
        <div class="link-preview-body">
          <p class="link-preview-domain">${escapeHtml(data.domain || '')}</p>
          <p class="link-preview-title">${escapeHtml(data.title || '')}</p>
          ${data.description ? `<p class="link-preview-desc">${escapeHtml(data.description)}</p>` : ''}
        </div>
      </div>
    `;
  }

  function populateHiddenFields(data) {
    setHiddenById('post_link_url',         data.url || '');
    setHiddenById('post_link_title',       data.title || '');
    setHiddenById('post_link_description', data.description || '');
    setHiddenById('post_link_image_url',   data.image || '');
    setHiddenById('post_link_domain',      data.domain || '');
  }

  function setHiddenById(id, value) {
    const el = document.getElementById(id);
    if (el) el.value = value;
  }

  function getOrCreatePreviewContainer() {
    let el = document.getElementById('link-preview-area');
    if (!el) {
      el = document.createElement('div');
      el.id = 'link-preview-area';
      const imageArea = document.getElementById('post-image-preview-area');
      if (imageArea) imageArea.after(el);
    }
    return el;
  }

  function removePreviews() {
    const el = document.getElementById('link-preview-area');
    if (el) el.innerHTML = '';
    lastFetchedUrl = null;
    ['post_link_url','post_link_title','post_link_description','post_link_image_url','post_link_domain']
      .forEach(id => {
        const el = document.getElementById(id);
        if (el) el.value = '';
      });
  }

  function escapeHtml(str) {
    const div = document.createElement('div');
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
  }

  // Exposed globally for the close button
  window.removeLinkPreview = function () {
    removePreviews();
  };

  document.addEventListener('DOMContentLoaded', init);
  document.addEventListener('turbo:load', init);
})();
