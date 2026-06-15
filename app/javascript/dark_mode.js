// ── Dark Mode Manager ────────────────────────────────────────────
// Handles toggle button click → PATCH /settings/dark_mode → persists to DB
// Also applies saved preference instantly from <body data-dark-mode>

(function () {
  const TOGGLE_BTN_ID = 'darkModeToggle';

  function applyDarkMode(enabled) {
    document.documentElement.classList.toggle('dark-mode', enabled);
    document.body.classList.toggle('dark-mode', enabled);
    const btn = document.getElementById(TOGGLE_BTN_ID);
    if (btn) btn.textContent = enabled ? '☀️' : '🌙';
  }

  function init() {
    // Read server-set preference from body attribute
    const serverPref = document.body.dataset.darkMode === 'true';
    applyDarkMode(serverPref);

    const btn = document.getElementById(TOGGLE_BTN_ID);
    if (!btn) return;

    btn.addEventListener('click', async () => {
      const isDark = document.body.classList.contains('dark-mode');
      const newState = !isDark;

      // Optimistic UI update
      applyDarkMode(newState);

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
        const response = await fetch('/settings/dark_mode', {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': csrfToken || '',
          },
          body: JSON.stringify({ dark_mode: newState }),
        });

        if (!response.ok) {
          // Revert on failure
          applyDarkMode(isDark);
          console.warn('Dark mode toggle failed');
        }
      } catch (err) {
        // Revert on network error
        applyDarkMode(isDark);
        console.error('Dark mode toggle error:', err);
      }
    });
  }

  // Run on DOM ready and after Turbo navigations
  document.addEventListener('DOMContentLoaded', init);
  document.addEventListener('turbo:load', init);
  document.addEventListener('turbo:render', () => {
    const serverPref = document.body.dataset.darkMode === 'true';
    applyDarkMode(serverPref);
  });
})();
