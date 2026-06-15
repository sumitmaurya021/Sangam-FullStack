// ╔══════════════════════════════════════════════════════╗
// ║  BOOKMARKS — Save / Unsave posts AND reels          ║
// ╚══════════════════════════════════════════════════════╝

// ── Post bookmark toggle ────────────────────────────────
window.toggleBookmark = async function(postId, btn) {
  const isBookmarked = btn.dataset.bookmarked === 'true';
  const csrfToken    = document.querySelector('meta[name="csrf-token"]').content;
  const url          = isBookmarked ? `/posts/${postId}/unbookmark` : `/posts/${postId}/bookmark`;
  const method       = isBookmarked ? 'DELETE' : 'POST';

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

      // Sync dropdown item if visible
      const dropdownBtn = btn.closest('.post-card')
                            ?.querySelector('[onclick*="toggleBookmark"]');
      if (dropdownBtn && dropdownBtn !== btn) {
        dropdownBtn.dataset.bookmarked = data.bookmarked ? 'true' : 'false';
        dropdownBtn.textContent = data.bookmarked ? '🔖 Saved' : '🔖 Save Post';
      }

      showBkToast(data.message || (data.bookmarked ? 'Post saved!' : 'Post unsaved'));
    }
  } catch (e) {
    showBkToast('Something went wrong', 'error');
  } finally {
    btn.disabled = false;
  }
};

// ── Reel bookmark toggle ────────────────────────────────
window.toggleReelBookmark = async function(reelId, btn) {
  const isBookmarked = btn.dataset.bookmarked === 'true';
  const csrfToken    = document.querySelector('meta[name="csrf-token"]').content;
  const url          = isBookmarked
    ? `/reels/${reelId}/unbookmark_reel`
    : `/reels/${reelId}/bookmark_reel`;
  const method = isBookmarked ? 'DELETE' : 'POST';

  btn.disabled = true;

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
      const nowSaved = data.bookmarked;
      btn.dataset.bookmarked = nowSaved ? 'true' : 'false';
      btn.classList.toggle('bookmarked', nowSaved);
      btn.title = nowSaved ? 'Remove from saved' : 'Save reel';

      // Swap fill on the SVG icon
      const icon = document.getElementById(`reel-bookmark-icon-${reelId}`);
      if (icon) icon.setAttribute('fill', nowSaved ? 'currentColor' : 'none');

      // Update label
      const label = document.getElementById(`reel-bookmark-label-${reelId}`);
      if (label) label.textContent = nowSaved ? 'Saved' : 'Save';

      showBkToast(data.message || (nowSaved ? 'Reel saved!' : 'Reel unsaved'));
    }
  } catch (e) {
    showBkToast('Something went wrong', 'error');
  } finally {
    btn.disabled = false;
  }
};

// ── Toast ───────────────────────────────────────────────
function showBkToast(message, type = 'success') {
  if (window.showFlash) { window.showFlash(message, type); return; }
  const toast = document.createElement('div');
  toast.textContent = message;
  toast.style.cssText = [
    'position:fixed', 'bottom:24px', 'left:50%', 'transform:translateX(-50%)',
    `background:${type === 'error' ? '#e74c3c' : '#23a55a'}`, 'color:#fff',
    'padding:10px 22px', 'border-radius:20px', 'font-size:14px', 'font-weight:600',
    'z-index:9999', 'box-shadow:0 4px 14px rgba(0,0,0,.25)',
    'animation:fadeInUp .22s ease', 'white-space:nowrap'
  ].join(';');
  document.body.appendChild(toast);
  setTimeout(() => toast.remove(), 2800);
}
