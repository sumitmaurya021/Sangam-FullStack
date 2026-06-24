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

// Add CSS for slide down animation
const style = document.createElement('style');
style.textContent = `
  @keyframes slideDown {
    from {
      opacity: 0;
      transform: translateY(-10px);
    }
    to {
      opacity: 1;
      transform: translateY(0);
    }
  }
`;
document.head.appendChild(style);

// ─── Profile Infinite Scroll ───────────────────────────────────────────────────
(function () {
  let profileScrollObserver = null;

  function initProfileInfiniteScroll() {
    const feed     = document.getElementById('profile-posts-feed');
    const sentinel = document.getElementById('profile-infinite-scroll-sentinel');
    const spinner  = document.getElementById('profile-posts-loading-spinner');

    if (!feed || !sentinel) return;

    // Tear down any previous observer
    if (profileScrollObserver) {
      profileScrollObserver.disconnect();
      profileScrollObserver = null;
    }

    feed.dataset.loading = 'false';

    function loadNextProfilePage() {
      const nextPage  = feed.dataset.nextPage;
      const isLoading = feed.dataset.loading === 'true';

      if (!nextPage || isLoading) return;

      feed.dataset.loading = 'true';
      if (spinner) spinner.style.display = 'block';

      // Hit current URL path + nextPage query param
      const url = window.location.pathname + '?page=' + nextPage;

      fetch(url, {
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })
        .then(function (res) {
          if (!res.ok) throw new Error('Response error');
          return res.json();
        })
        .then(function (data) {
          if (spinner) spinner.style.display = 'none';

          const tempDiv = document.createElement('div');
          tempDiv.innerHTML = data.posts_html;

          // Add fade-in animation or styling to new posts
          const newCards = tempDiv.querySelectorAll('.post-card');
          newCards.forEach(function(card, idx) {
            card.style.opacity = '0';
            card.style.transform = 'translateY(15px)';
            card.style.transition = 'all 0.4s ease';
            card.style.transitionDelay = (idx * 0.08) + 's';
            setTimeout(() => {
              card.style.opacity = '1';
              card.style.transform = 'translateY(0)';
            }, 50);
          });

          feed.insertAdjacentHTML('beforeend', tempDiv.innerHTML);
          feed.dataset.nextPage = data.next_page || '';
          feed.dataset.loading  = 'false';

          if (!data.next_page) {
            profileScrollObserver.disconnect();
            profileScrollObserver = null;
          }
        })
        .catch(function (err) {
          console.error('Profile infinite scroll error:', err);
          feed.dataset.loading = 'false';
          if (spinner) spinner.style.display = 'none';
        });
    }

    profileScrollObserver = new IntersectionObserver(
      function (entries) {
        entries.forEach(function (entry) {
          if (entry.isIntersecting) loadNextProfilePage();
        });
      },
      {
        rootMargin: '0px 0px 400px 0px',
        threshold: 0
      }
    );

    profileScrollObserver.observe(sentinel);
  }

  document.addEventListener('turbo:load', initProfileInfiniteScroll);

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initProfileInfiniteScroll);
  } else {
    initProfileInfiniteScroll();
  }
}());
