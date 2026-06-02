// ╔══════════════════════════════════════════════════╗
// ║  BOOKMARKS — Save / Unsave posts                ║
// ╚══════════════════════════════════════════════════╝

window.toggleBookmark = async function(postId, btn) {
  const isBookmarked = btn.dataset.bookmarked === 'true';
  const csrfToken    = document.querySelector('meta[name="csrf-token"]').content;

  const url    = isBookmarked ? `/posts/${postId}/unbookmark` : `/posts/${postId}/bookmark`;
  const method = isBookmarked ? 'DELETE' : 'POST';

  // Optimistic UI
  btn.disabled = true;
  const textEl = document.getElementById(`bookmark-text-${postId}`);

  try {
    const res  = await fetch(url, {
      method,
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      }
    });
    const data = await res.json();

    if (data.bookmarked !== undefined) {
      btn.dataset.bookmarked = data.bookmarked ? 'true' : 'false';
      if (textEl) textEl.textContent = data.bookmarked ? 'Saved' : 'Save';
      btn.classList.toggle('active', data.bookmarked);

      // Also update dropdown if it exists
      const dropdownBtn = btn.closest('.post-dropdown')?.querySelector('[onclick*="toggleBookmark"]');
      if (dropdownBtn) {
        dropdownBtn.dataset.bookmarked = data.bookmarked ? 'true' : 'false';
        dropdownBtn.textContent = data.bookmarked ? '🔖 Saved' : '🔖 Save Post';
      }

      showToast(data.message || (data.bookmarked ? 'Post saved!' : 'Post unsaved'), 'success');
    }
  } catch (e) {
    showToast('Something went wrong', 'error');
  } finally {
    btn.disabled = false;
  }
};

// Light toast notification (reused from existing if available)
function showToast(message, type = 'success') {
  if (window.showFlash) { window.showFlash(message, type); return; }
  const toast = document.createElement('div');
  toast.className = `toast toast-${type}`;
  toast.textContent = message;
  toast.style.cssText = `
    position:fixed; bottom:24px; left:50%; transform:translateX(-50%);
    background:${type === 'success' ? '#23a55a' : '#e74c3c'}; color:#fff;
    padding:10px 20px; border-radius:8px; font-size:14px; font-weight:600;
    z-index:9999; box-shadow:0 4px 12px rgba(0,0,0,.2);
    animation: fadeInUp .25s ease;
  `;
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 3000);
}
