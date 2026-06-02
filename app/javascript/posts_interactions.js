// Reaction Picker Toggle
function toggleReactionPicker(postId) {
  const picker = document.getElementById(`reaction-picker-${postId}`);
  const allPickers = document.querySelectorAll('.reaction-picker');
  
  // Close all other pickers
  allPickers.forEach(p => {
    if (p.id !== `reaction-picker-${postId}`) {
      p.style.display = 'none';
    }
  });
  
  // Toggle current picker
  if (picker.style.display === 'none' || picker.style.display === '') {
    picker.style.display = 'flex';
  } else {
    picker.style.display = 'none';
  }
}

// React to Post
async function reactToPost(postId, reactionType) {
  try {
    const response = await fetch(`/posts/${postId}/like`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      },
      body: JSON.stringify({ reaction_type: reactionType })
    });
    
    if (response.ok) {
      const data = await response.json();
      
      // Update button text and style
      const likeBtn = document.getElementById(`like-btn-${postId}`);
      const likeText = document.getElementById(`like-text-${postId}`);
      const reactionEmojis = {
        'like': '👍',
        'love': '❤️',
        'haha': '😆',
        'wow': '😮',
        'sad': '😢',
        'angry': '😠'
      };
      
      likeBtn.classList.add('active');
      likeText.innerHTML = `${reactionEmojis[reactionType]} ${reactionType.charAt(0).toUpperCase() + reactionType.slice(1)}`;
      
      // Hide picker
      document.getElementById(`reaction-picker-${postId}`).style.display = 'none';
      
      // Reload to update counts (or use Turbo Streams for real-time update)
      setTimeout(() => location.reload(), 500);
    }
  } catch (error) {
    console.error('Error reacting to post:', error);
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

// Open Image Gallery (placeholder - implement modal later)
function openImageGallery(postId, imageIndex) {
  console.log(`Opening gallery for post ${postId}, image ${imageIndex}`);
  // TODO: Implement image gallery modal
  alert('Image gallery feature - coming soon!');
}

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
  const allMenus = document.querySelectorAll('.post-dropdown');
  
  // Close all other menus
  allMenus.forEach(m => {
    if (m.id !== `postMenu${postId}`) {
      m.style.display = 'none';
    }
  });
  
  // Toggle current menu
  if (menu.style.display === 'none' || menu.style.display === '') {
    menu.style.display = 'block';
  } else {
    menu.style.display = 'none';
  }
}

// Close pickers and menus when clicking outside
document.addEventListener('click', function(event) {
  if (!event.target.closest('.action-btn-wrapper') && !event.target.closest('.reaction-picker')) {
    document.querySelectorAll('.reaction-picker').forEach(picker => {
      picker.style.display = 'none';
    });
  }
  
  if (!event.target.closest('.post-menu')) {
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
