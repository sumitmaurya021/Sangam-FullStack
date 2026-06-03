// Toggle User Menu
function toggleUserMenu() {
  const dropdown = document.getElementById('userDropdown');
  dropdown.classList.toggle('show');
}

// Toggle Post Menu — handled globally by posts_interactions.js
// (kept as a no-op stub so any inline onclick="togglePostMenu(...)" calls still work
//  even if posts_interactions loads after feed.js on some pages)
if (typeof window.togglePostMenu === 'undefined') {
  window.togglePostMenu = function(postId) {
    const menu = document.getElementById('postMenu' + postId);
    if (!menu) return;
    const isVisible = menu.style.display === 'block';
    document.querySelectorAll('.post-dropdown').forEach(m => { m.style.display = 'none'; });
    if (!isVisible) menu.style.display = 'block';
  };
}

// Toggle Comments Section
function toggleComments(postId) {
  const commentsSection = document.getElementById(`comments-${postId}`);
  if (commentsSection.style.display === 'none' || commentsSection.style.display === '') {
    commentsSection.style.display = 'block';
    commentsSection.style.animation = 'slideDown 0.3s ease';
  } else {
    commentsSection.style.display = 'none';
  }
}

// Close dropdowns when clicking outside
document.addEventListener('click', function(event) {
  // Close user menu
  const userMenu = document.querySelector('.user-menu');
  const userDropdown = document.getElementById('userDropdown');
  if (userMenu && !userMenu.contains(event.target)) {
    userDropdown?.classList.remove('show');
  }
  
  // Close post menus
  const postMenus = document.querySelectorAll('.post-menu');
  postMenus.forEach(menu => {
    if (!menu.contains(event.target)) {
      const dropdown = menu.querySelector('.post-dropdown');
      dropdown?.classList.remove('show');
    }
  });
});

// Like button animation
document.addEventListener('DOMContentLoaded', function() {
  const likeBtns = document.querySelectorAll('.action-btn');
  
  likeBtns.forEach(btn => {
    btn.addEventListener('click', function(e) {
      if (this.querySelector('.action-icon')) {
        const icon = this.querySelector('.action-icon');
        
        // Create heart animation
        const heart = document.createElement('div');
        heart.innerHTML = '❤️';
        heart.style.position = 'absolute';
        heart.style.fontSize = '2rem';
        heart.style.pointerEvents = 'none';
        heart.style.animation = 'floatHeart 1s ease-out forwards';
        heart.style.left = e.clientX + 'px';
        heart.style.top = e.clientY + 'px';
        
        document.body.appendChild(heart);
        
        setTimeout(() => {
          heart.remove();
        }, 1000);
      }
    });
  });
});

// Add CSS for heart animation
const style = document.createElement('style');
style.textContent = `
  @keyframes floatHeart {
    0% {
      opacity: 1;
      transform: translateY(0) scale(0);
    }
    50% {
      opacity: 1;
      transform: translateY(-30px) scale(1.2);
    }
    100% {
      opacity: 0;
      transform: translateY(-60px) scale(0.8);
    }
  }

  .posts-spinner {
    display: inline-block;
    width: 36px;
    height: 36px;
    border: 4px solid #e4e6ea;
    border-top-color: #1877f2;
    border-radius: 50%;
    animation: spin 0.7s linear infinite;
  }

  @keyframes spin {
    to { transform: rotate(360deg); }
  }
`;
document.head.appendChild(style);

// Auto-expand textarea
document.addEventListener('DOMContentLoaded', function() {
  const textareas = document.querySelectorAll('.post-input, .comment-input');
  
  textareas.forEach(textarea => {
    textarea.addEventListener('input', function() {
      this.style.height = 'auto';
      this.style.height = this.scrollHeight + 'px';
    });
  });
});

// Image preview for post creation — uses event delegation so it works
// after Turbo Stream replaces the create-post-form-wrapper
document.addEventListener('change', function(e) {
  if (!e.target.matches('#new-post-form .file-input')) return;

  const fileInput = e.target;
  const files = Array.from(fileInput.files).filter(f => f.type.startsWith('image/'));
  if (!files.length) return;

  // Find preview area inside the same form
  const form = fileInput.closest('form');
  if (!form) return;
  const previewArea = form.querySelector('#post-image-preview-area');
  if (!previewArea) return;

  previewArea.innerHTML = '';

  const wrapper = document.createElement('div');
  wrapper.style.cssText = 'display:flex;gap:8px;flex-wrap:wrap;margin:0.75rem 0;';

  files.forEach((file, idx) => {
    const reader = new FileReader();
    reader.onload = function(ev) {
      const item = document.createElement('div');
      item.style.cssText = 'position:relative;border-radius:8px;overflow:hidden;';

      const img = document.createElement('img');
      img.src = ev.target.result;
      img.style.cssText = 'width:80px;height:80px;object-fit:cover;display:block;border-radius:8px;border:2px solid #e4e6ea;';

      const removeBtn = document.createElement('button');
      removeBtn.type = 'button';
      removeBtn.innerHTML = '✕';
      removeBtn.style.cssText = 'position:absolute;top:2px;right:2px;width:20px;height:20px;border-radius:50%;background:rgba(0,0,0,0.65);color:white;border:none;cursor:pointer;font-size:11px;display:flex;align-items:center;justify-content:center;';
      removeBtn.addEventListener('click', () => {
        previewArea.innerHTML = '';
        fileInput.value = '';
      });

      item.appendChild(img);
      item.appendChild(removeBtn);
      wrapper.appendChild(item);
    };
    reader.readAsDataURL(file);
  });

  previewArea.appendChild(wrapper);
});

// ─── Infinite Scroll ───────────────────────────────────────────────────────────
(function () {
  let scrollObserver = null;

  function initInfiniteScroll() {
    const feed     = document.getElementById('posts-feed');
    const sentinel = document.getElementById('infinite-scroll-sentinel');
    const spinner  = document.getElementById('posts-loading-spinner');

    // Not on the feed page — nothing to do
    if (!feed || !sentinel) return;

    // Tear down any previous observer (Turbo re-uses the same JS context
    // across navigations, so we must clean up before re-initialising)
    if (scrollObserver) {
      scrollObserver.disconnect();
      scrollObserver = null;
    }

    // Reset loading flag on every page visit
    feed.dataset.loading = 'false';

    function loadNextPage() {
      const nextPage  = feed.dataset.nextPage;
      const isLoading = feed.dataset.loading === 'true';

      if (!nextPage || isLoading) return;

      feed.dataset.loading  = 'true';
      spinner.style.display = 'block';

      fetch('/posts?page=' + nextPage, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
        .then(function (res) {
          if (!res.ok) throw new Error('Network response was not ok');
          return res.json();
        })
        .then(function (data) {
          feed.insertAdjacentHTML('beforeend', data.posts_html);

          feed.dataset.nextPage = data.next_page || '';
          feed.dataset.loading  = 'false';
          spinner.style.display = 'none';

          if (!data.next_page) {
            // All pages loaded — stop observing
            scrollObserver.disconnect();
            scrollObserver = null;
          }
        })
        .catch(function () {
          feed.dataset.loading  = 'false';
          spinner.style.display = 'none';
        });
    }

    scrollObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) loadNextPage();
        });
      },
      {
        // Fire 400px before the sentinel reaches the viewport so the next
        // batch is ready before the user actually hits the bottom.
        // Works correctly at every viewport width because rootMargin is
        // applied relative to the viewport, not the layout columns.
        rootMargin: '0px 0px 400px 0px',
        threshold: 0
      }
    );

    scrollObserver.observe(sentinel);
  }

  // turbo:load fires on first load AND after every Turbo navigation.
  // This replaces DOMContentLoaded so infinite scroll works after
  // navigating back to the feed without a full page reload.
  document.addEventListener('turbo:load', initInfiniteScroll);

  // Fallback for pages served without Turbo Drive (e.g. direct navigation
  // when Turbo is disabled on a link).
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initInfiniteScroll);
  } else {
    // Document already parsed — run immediately
    initInfiniteScroll();
  }
}());
