// ── Bookmark Collections Manager ──────────────────────────────────
// Adds "Save to Collection" modal when user saves a post

window.showCollectionPicker = async function (postId, bookmarkBtn) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

  // First bookmark the post (if not already)
  const isBookmarked = bookmarkBtn?.dataset?.bookmarked === 'true';

  // Fetch collections
  try {
    const resp = await fetch('/bookmark_collections', {
      headers: { 'Accept': 'application/json', 'X-CSRF-Token': csrfToken }
    });
    const collections = await resp.json();
    renderCollectionModal(postId, collections, csrfToken);
  } catch (e) {
    console.error('Collections fetch error', e);
  }
};

function renderCollectionModal(postId, collections, csrfToken) {
  // Remove existing modal
  document.getElementById('collection-modal')?.remove();

  const modal = document.createElement('div');
  modal.id = 'collection-modal';
  modal.className = 'collection-modal-overlay';
  modal.innerHTML = `
    <div class="collection-modal">
      <div class="collection-modal__header">
        <h3>Save to Collection</h3>
        <button onclick="document.getElementById('collection-modal').remove()" class="collection-modal__close">✕</button>
      </div>
      <div class="collection-modal__body">
        ${collections.map(c => `
          <button class="collection-option" onclick="addToCollection(${c.id}, ${postId})">
            <div class="collection-option__thumb">${c.cover ? `<img src="${c.cover}" alt="${c.name}">` : '🔖'}</div>
            <div class="collection-option__info">
              <span class="collection-option__name">${c.name}</span>
              <span class="collection-option__count">${c.count} items</span>
            </div>
          </button>
        `).join('')}
        <button class="collection-option collection-option--new" onclick="createCollectionPrompt(${postId})">
          <div class="collection-option__thumb">➕</div>
          <div class="collection-option__info">
            <span class="collection-option__name">New Collection</span>
          </div>
        </button>
      </div>
    </div>
  `;
  document.body.appendChild(modal);
  modal.addEventListener('click', (e) => { if (e.target === modal) modal.remove(); });
}

window.addToCollection = async function (collectionId, bookmarkableId) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  // Find the bookmark for this post
  try {
    // Get bookmark id from the post
    const resp = await fetch(`/bookmark_collections/${collectionId}/add_bookmark`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ post_id: bookmarkableId })
    });
    document.getElementById('collection-modal')?.remove();
    showCollectionToast('Saved to collection! 📂');
  } catch (e) {
    console.error('Add to collection error', e);
  }
};

window.createCollectionPrompt = function (postId) {
  const name = prompt('Collection name:');
  if (!name?.trim()) return;
  createCollection(name.trim(), postId);
};

async function createCollection(name, postId) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  try {
    const resp = await fetch('/bookmark_collections', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken
      },
      body: JSON.stringify({ bookmark_collection: { name } })
    });
    const data = await resp.json();
    if (data.success) {
      document.getElementById('collection-modal')?.remove();
      showCollectionToast(`Collection "${name}" created! 📂`);
    }
  } catch (e) {
    console.error('Create collection error', e);
  }
}

function showCollectionToast(msg) {
  const toast = document.createElement('div');
  toast.className = 'collection-toast';
  toast.textContent = msg;
  document.body.appendChild(toast);
  setTimeout(() => toast.classList.add('show'), 10);
  setTimeout(() => { toast.classList.remove('show'); setTimeout(() => toast.remove(), 300); }, 2500);
}
