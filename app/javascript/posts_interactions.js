// Helper: hide a picker then clear inline styles so CSS :hover can re-trigger
function hidePicker(picker) {
  if (!picker) return;
  picker.style.display = 'none';
  picker.style.opacity = '0';
  picker.style.pointerEvents = 'none';
  // Remove inline styles after transition so CSS hover rules work again
  setTimeout(() => {
    picker.style.removeProperty('display');
    picker.style.removeProperty('opacity');
    picker.style.removeProperty('pointer-events');
  }, 350);
}

// Reaction Picker Toggle (fallback for mobile/touch devices)
// On desktop, hover handles it via CSS
function toggleReactionPicker(postId) {
  const picker = document.getElementById(`reaction-picker-${postId}`);
  const allPickers = document.querySelectorAll('.reaction-picker');
  
  if (!picker) return;

  const isVisible = picker.style.display === 'flex' || picker.classList.contains('picker-open');

  // Close all other pickers
  allPickers.forEach(p => {
    if (p.id !== `reaction-picker-${postId}`) {
      p.classList.remove('picker-open');
      hidePicker(p);
    }
  });
  
  // Toggle current picker (mobile only)
  if (!isVisible) {
    picker.style.display = 'flex';
    picker.style.opacity = '1';
    picker.style.pointerEvents = 'all';
    picker.classList.add('picker-open');
  } else {
    picker.classList.remove('picker-open');
    hidePicker(picker);
  }
}

// Mobile touch support — tap on like button shows reactions
document.addEventListener('DOMContentLoaded', function() {
  // Detect touch device
  const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
  
  if (isTouchDevice) {
    document.addEventListener('click', function(e) {
      const likeBtn = e.target.closest('.action-btn-wrapper .action-btn');
      
      if (likeBtn) {
        // Like button clicked on touch device — toggle picker
        const wrapper = likeBtn.closest('.action-btn-wrapper');
        const picker = wrapper?.querySelector('.reaction-picker');
        if (picker) {
          const postId = picker.id.replace('reaction-picker-', '');
          toggleReactionPicker(postId);
          e.preventDefault();
          e.stopPropagation();
        }
      } else if (!e.target.closest('.action-btn-wrapper') && !e.target.closest('.reaction-picker')) {
        // Clicked outside — close all pickers
        document.querySelectorAll('.reaction-picker').forEach(picker => {
          picker.classList.remove('picker-open');
          hidePicker(picker);
        });
      }
    });
  }
});

// React to Post with Optimistic UI Update
async function reactToPost(postId, reactionType) {
  // Reaction emoji mapping
  const reactionEmojis = {
    'like': '👍',
    'love': '❤️',
    'haha': '😆',
    'wow': '😮',
    'sad': '😢',
    'angry': '😠'
  };
  
  // Get elements
  const likeBtn = document.getElementById(`like-btn-${postId}`);
  const likeText = document.getElementById(`like-text-${postId}`);
  const likesCount = document.getElementById(`likes-count-${postId}`);
  const reactionSummary = document.getElementById(`reaction-summary-${postId}`);
  const picker = document.getElementById(`reaction-picker-${postId}`);
  
  // Store original state for rollback
  const wasActive = likeBtn?.classList.contains('active');
  const originalText = likeText?.innerHTML;
  const originalCount = likesCount?.textContent;
  const originalSummary = reactionSummary?.innerHTML;
  
  // ===== OPTIMISTIC UPDATE - Instant UI change =====
  if (likeBtn && likeText) {
    likeBtn.classList.add('active');
    const emoji = reactionEmojis[reactionType] || '👍';
    const label = reactionType.charAt(0).toUpperCase() + reactionType.slice(1);
    likeText.innerHTML = `${emoji} ${label}`;
    
    // Hide the SVG like icon when reacting (only show emoji)
    const likeIcon = document.getElementById(`like-icon-${postId}`) || likeBtn.querySelector('.action-icon');
    if (likeIcon) likeIcon.style.display = 'none';
  }
  
  if (likesCount) {
    const currentCount = parseInt(likesCount.textContent) || 0;
    likesCount.textContent = wasActive ? currentCount : currentCount + 1;
  }
  
  // Hide picker immediately, then clear inline styles for CSS hover
  if (picker) {
    picker.classList.remove('picker-open');
    hidePicker(picker);
  }
  
  // ===== Background server request =====
  try {
    const response = await fetch(`/posts/${postId}/like`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ reaction_type: reactionType })
    });
    
    if (response.ok) {
      const data = await response.json();
      
      // Sync with server response (correct any mismatch)
      if (likesCount && data.likes_count !== undefined) {
        likesCount.textContent = data.likes_count;
      }
      
      // Update reaction summary icons with actual server data
      if (reactionSummary && data.reaction_counts) {
        reactionSummary.innerHTML = '';
        const counts = Object.entries(data.reaction_counts).slice(0, 3);
        counts.forEach(([type, count]) => {
          const icon = document.createElement('span');
          icon.className = `reaction-icon ${type}`;
          icon.textContent = reactionEmojis[type] || '👍';
          reactionSummary.appendChild(icon);
        });
        
        if (counts.length === 0) {
          const icon = document.createElement('span');
          icon.className = 'reaction-icon like';
          icon.textContent = '👍';
          reactionSummary.appendChild(icon);
        }
      }
    } else {
      // Server error - rollback optimistic update
      console.error('Failed to react to post');
      if (likeBtn && originalText) {
        if (wasActive) likeBtn.classList.add('active');
        else likeBtn.classList.remove('active');
        likeText.innerHTML = originalText;
      }
      if (likesCount && originalCount) {
        likesCount.textContent = originalCount;
      }
      if (reactionSummary && originalSummary) {
        reactionSummary.innerHTML = originalSummary;
      }
    }
  } catch (error) {
    // Network error - rollback optimistic update
    console.error('Error reacting to post:', error);
    if (likeBtn && originalText) {
      if (wasActive) likeBtn.classList.add('active');
      else likeBtn.classList.remove('active');
      likeText.innerHTML = originalText;
    }
    if (likesCount && originalCount) {
      likesCount.textContent = originalCount;
    }
    if (reactionSummary && originalSummary) {
      reactionSummary.innerHTML = originalSummary;
    }
  }
}

// Reply to Comment
function replyToComment(postId, commentId, userName, userId) {
  const parentIdField = document.getElementById(`parent-id-${postId}`);
  const repliedToUserIdField = document.getElementById(`replied-to-user-id-${postId}`);
  const replyIndicator = document.getElementById(`reply-indicator-${postId}`);
  const replyToName = document.getElementById(`reply-to-name-${postId}`);
  const commentInput = document.querySelector(`#comment-form-${postId} .comment-input`);

  parentIdField.value = commentId;
  if (repliedToUserIdField) repliedToUserIdField.value = userId;
  replyToName.textContent = userName;
  replyIndicator.style.display = 'flex';
  commentInput.focus();
  commentInput.placeholder = `Reply to ${userName}...`;
}

// Cancel Reply
function cancelReply(postId) {
  const parentIdField = document.getElementById(`parent-id-${postId}`);
  const repliedToUserIdField = document.getElementById(`replied-to-user-id-${postId}`);
  const replyIndicator = document.getElementById(`reply-indicator-${postId}`);
  const commentInput = document.querySelector(`#comment-form-${postId} .comment-input`);

  parentIdField.value = '';
  if (repliedToUserIdField) repliedToUserIdField.value = '';
  replyIndicator.style.display = 'none';
  commentInput.placeholder = 'Write a comment...';
}

// Toggle Replies
function toggleReplies(commentId) {
  const repliesContainer = document.getElementById(`replies-${commentId}`);
  const repliesText = document.getElementById(`replies-text-${commentId}`);
  const icon = document.getElementById(`toggle-replies-icon-${commentId}`);

  if (repliesContainer.style.display === 'none' || repliesContainer.style.display === '') {
    repliesContainer.style.display = 'block';
    repliesText.textContent = 'Hide replies';
    if (icon) icon.style.transform = 'rotate(0deg)';
  } else {
    repliesContainer.style.display = 'none';
    const replyCount = repliesContainer.querySelectorAll('.reply-item').length;
    repliesText.textContent = `View ${replyCount} ${replyCount === 1 ? 'reply' : 'replies'}`;
    if (icon) icon.style.transform = 'rotate(-90deg)';
  }
}

// Lightbox State
let currentGalleryUrls = [];
let currentGalleryIndex = 0;

// Open Image Gallery
window.openImageGallery = function(postId, imageIndex) {
  const container = document.getElementById(`post-images-${postId}`);
  if (!container) return;

  const rawUrls = container.getAttribute('data-urls');
  if (!rawUrls) return;

  try {
    currentGalleryUrls = JSON.parse(rawUrls);
    currentGalleryIndex = imageIndex;
    
    if (currentGalleryUrls.length > 0) {
      window.updateLightboxImage();
      document.getElementById('imageLightbox').classList.add('show');
      document.body.style.overflow = 'hidden'; // Prevent background scrolling
    }
  } catch (e) {
    console.error("Failed to parse image URLs:", e);
  }
};

// Close Image Gallery
window.closeImageGallery = function() {
  document.getElementById('imageLightbox').classList.remove('show');
  document.body.style.overflow = '';
};

// Change Image (Prev/Next)
window.changeLightboxImage = function(direction) {
  currentGalleryIndex += direction;
  
  if (currentGalleryIndex >= currentGalleryUrls.length) {
    currentGalleryIndex = 0; // wrap to first
  } else if (currentGalleryIndex < 0) {
    currentGalleryIndex = currentGalleryUrls.length - 1; // wrap to last
  }
  
  window.updateLightboxImage();
};

// Update Image Source
window.updateLightboxImage = function() {
  const imgElement = document.getElementById('lightboxImg');
  const captionElement = document.getElementById('lightboxCaption');
  
  if (imgElement && currentGalleryUrls.length > 0) {
    imgElement.src = currentGalleryUrls[currentGalleryIndex];
    if (captionElement) {
      captionElement.textContent = `Image ${currentGalleryIndex + 1} of ${currentGalleryUrls.length}`;
    }
  }
};

// Close on escape key and handle arrow keys
document.addEventListener('keydown', function(event) {
  const lightbox = document.getElementById('imageLightbox');
  if (lightbox && lightbox.classList.contains('show')) {
    if (event.key === "Escape") {
      window.closeImageGallery();
    } else if (event.key === "ArrowLeft") {
      window.changeLightboxImage(-1);
    } else if (event.key === "ArrowRight") {
      window.changeLightboxImage(1);
    }
  }
});

// Toggle Comments Section
function toggleComments(postId) {
  const commentsSection = document.getElementById(`comments-${postId}`);
  if (commentsSection.style.display === 'none' || commentsSection.style.display === '') {
    commentsSection.style.display = 'block';
  } else {
    commentsSection.style.display = 'none';
  }
}

// Toggle Post Menu
function togglePostMenu(postId) {
  const menu = document.getElementById(`postMenu${postId}`);
  if (!menu) return;

  const isVisible = menu.style.display === 'block';

  // Close all dropdowns first
  document.querySelectorAll('.post-dropdown').forEach(m => {
    m.style.display = 'none';
  });

  // Toggle current one
  if (!isVisible) {
    menu.style.display = 'block';
  }
}

// Close pickers and menus when clicking outside (mobile only)
document.addEventListener('click', function(event) {
  const isTouchDevice = 'ontouchstart' in window || navigator.maxTouchPoints > 0;
  
  // On touch devices, manually close reaction pickers
  if (isTouchDevice) {
    if (!event.target.closest('.action-btn-wrapper') && !event.target.closest('.reaction-picker')) {
      document.querySelectorAll('.reaction-picker').forEach(picker => {
        picker.classList.remove('picker-open');
        hidePicker(picker);
      });
    }
  }

  // Close post menus only when clicking outside the post-menu container
  if (!event.target.closest('.post-menu') && !event.target.closest('.post-dropdown')) {
    document.querySelectorAll('.post-dropdown').forEach(menu => {
      menu.style.display = 'none';
    });
  }
});

// Export functions for use in inline handlers
window.toggleReactionPicker = toggleReactionPicker;
window.reactToPost = reactToPost;
window.replyToComment = replyToComment;
window.cancelReply = cancelReply;
window.toggleReplies = toggleReplies;
window.openImageGallery = openImageGallery;
window.toggleComments = toggleComments;
window.togglePostMenu = togglePostMenu;

// ─────────────────────────────────────────────────
//  @MENTION AUTOCOMPLETE in post textarea + comment
// ─────────────────────────────────────────────────
(function initMentionAutocomplete() {
  let mentionDropdown = null;
  let currentInput    = null;
  let mentionQuery    = '';
  let mentionStart    = -1;
  let debounceTimer   = null;

  function createDropdown() {
    if (mentionDropdown) return mentionDropdown;
    mentionDropdown = document.createElement('div');
    mentionDropdown.id = 'mention-dropdown';
    mentionDropdown.style.cssText = `
      position: absolute; z-index: 9999; background: #fff;
      border-radius: 10px; box-shadow: 0 4px 20px rgba(0,0,0,.2);
      min-width: 220px; max-height: 240px; overflow-y: auto;
      padding: 6px 0; font-family: inherit;
    `;
    document.body.appendChild(mentionDropdown);
    return mentionDropdown;
  }

  function positionDropdown(input) {
    const rect = input.getBoundingClientRect();
    const dd   = createDropdown();
    dd.style.top  = `${rect.bottom + window.scrollY + 4}px`;
    dd.style.left = `${rect.left  + window.scrollX}px`;
  }

  function closeMentionDropdown() {
    if (mentionDropdown) mentionDropdown.style.display = 'none';
    mentionQuery = '';
    mentionStart = -1;
    currentInput = null;
  }

  async function fetchMentionUsers(q) {
    try {
      const res  = await fetch(`/profiles/search?q=${encodeURIComponent(q)}`, {
        headers: { 'Accept': 'application/json' }
      });
      return await res.json();
    } catch { return []; }
  }

  function renderMentionDropdown(users, input) {
    const dd = createDropdown();
    if (!users.length) { dd.style.display = 'none'; return; }

    dd.innerHTML = users.slice(0, 6).map(u => `
      <div class="mention-item" data-name="${escHtml(u.name)}"
           style="display:flex;align-items:center;gap:10px;padding:8px 14px;cursor:pointer;transition:background .15s;">
        ${u.avatar
          ? `<img src="${u.avatar}" style="width:32px;height:32px;border-radius:50%;object-fit:cover;">`
          : `<div style="width:32px;height:32px;border-radius:50%;background:#667eea;color:#fff;display:flex;align-items:center;justify-content:center;font-weight:700;">${(u.name||'?')[0]}</div>`
        }
        <div>
          <div style="font-size:14px;font-weight:700;color:#050505;">${escHtml(u.name)}</div>
        </div>
      </div>
    `).join('');

    dd.querySelectorAll('.mention-item').forEach(item => {
      item.addEventListener('mouseenter', () => item.style.background = '#f0f2f5');
      item.addEventListener('mouseleave', () => item.style.background = '');
      item.addEventListener('click', () => insertMention(item.dataset.name, input));
    });

    positionDropdown(input);
    dd.style.display = 'block';
  }

  function insertMention(name, input) {
    const val   = input.value;
    const before = val.substring(0, mentionStart);
    const after  = val.substring(mentionStart + mentionQuery.length + 1);
    input.value  = `${before}@${name} ${after}`;
    input.selectionStart = input.selectionEnd = before.length + name.length + 2;
    input.focus();
    closeMentionDropdown();
  }

  function handleMentionInput(e) {
    const input = e.target;
    currentInput = input;
    const val    = input.value;
    const cursor = input.selectionStart;

    // Find last @ before cursor
    const textBefore = val.substring(0, cursor);
    const atIdx      = textBefore.lastIndexOf('@');

    if (atIdx === -1 || (atIdx > 0 && /\S/.test(val[atIdx - 1]))) {
      closeMentionDropdown();
      return;
    }

    const query = textBefore.substring(atIdx + 1);
    if (/\s/.test(query)) { closeMentionDropdown(); return; }

    mentionQuery = query;
    mentionStart = atIdx;

    if (query.length < 1) { closeMentionDropdown(); return; }

    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(async () => {
      const users = await fetchMentionUsers(query);
      renderMentionDropdown(users, input);
    }, 250);
  }

  function handleMentionKeydown(e) {
    if (!mentionDropdown || mentionDropdown.style.display === 'none') return;
    const items = mentionDropdown.querySelectorAll('.mention-item');
    const active = mentionDropdown.querySelector('.mention-item.hover-active');
    let idx = [...items].indexOf(active);

    if (e.key === 'ArrowDown') {
      e.preventDefault();
      active?.classList.remove('hover-active');
      items[Math.min(idx + 1, items.length - 1)]?.classList.add('hover-active');
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      active?.classList.remove('hover-active');
      items[Math.max(idx - 1, 0)]?.classList.add('hover-active');
    } else if (e.key === 'Enter' || e.key === 'Tab') {
      const hovered = mentionDropdown.querySelector('.mention-item.hover-active');
      if (hovered) { e.preventDefault(); insertMention(hovered.dataset.name, e.target); }
    } else if (e.key === 'Escape') {
      closeMentionDropdown();
    }
  }

  // Attach to all post textareas and comment inputs (now + future via delegation)
  document.addEventListener('input', e => {
    if (e.target.matches('.post-input, .comment-input, .story-text-input')) {
      handleMentionInput(e);
    }
  });
  document.addEventListener('keydown', e => {
    if (e.target.matches('.post-input, .comment-input, .story-text-input')) {
      handleMentionKeydown(e);
    }
  });
  document.addEventListener('click', e => {
    if (!e.target.closest('#mention-dropdown') && !e.target.matches('.post-input,.comment-input')) {
      closeMentionDropdown();
    }
  });

  function escHtml(str) {
    const d = document.createElement('div');
    d.textContent = str || '';
    return d.innerHTML;
  }
})();

// ─────────────────────────────────────────────────
// DWELL TRACKING FOR PERSONALIZED FEED
// ─────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  const dwellTimers = {};
  
  const trackInteraction = async (postId, type) => {
    try {
      const csrfToken = document.querySelector('[name="csrf-token"]')?.content;
      if (!csrfToken) return;
      
      await fetch('/api/interactions', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({ post_id: postId, interaction_type: type })
      });
    } catch (e) {
      console.error('Failed to log interaction', e);
    }
  };

  const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      const postId = entry.target.dataset.postId;
      if (!postId) return;

      if (entry.isIntersecting) {
        // Log Impression instantly
        trackInteraction(postId, 'impression');
        
        // Start Dwell timer (3 seconds)
        dwellTimers[postId] = setTimeout(() => {
          trackInteraction(postId, 'dwell');
        }, 3000);
      } else {
        // Clear Dwell timer if they scrolled away before 3s
        if (dwellTimers[postId]) {
          clearTimeout(dwellTimers[postId]);
          delete dwellTimers[postId];
        }
      }
    });
  }, { threshold: 0.5 }); // Trigger when 50% of the post is visible

  // Observe all current posts
  document.querySelectorAll('.post-card[data-post-id]').forEach(post => {
    observer.observe(post);
  });

  // Export for turbo/dynamic loading to attach observer to new posts
  window.observeNewPosts = function() {
    document.querySelectorAll('.post-card[data-post-id]').forEach(post => {
      observer.observe(post);
    });
  };
});
