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
function replyToComment(postId, commentId, userName) {
  const parentIdField = document.getElementById(`parent-id-${postId}`);
  const replyIndicator = document.getElementById(`reply-indicator-${postId}`);
  const replyToName = document.getElementById(`reply-to-name-${postId}`);
  const commentInput = document.querySelector(`#comment-form-${postId} .comment-input`);
  
  parentIdField.value = commentId;
  replyToName.textContent = userName;
  replyIndicator.style.display = 'flex';
  commentInput.focus();
  commentInput.placeholder = `Reply to ${userName}...`;
}

// Cancel Reply
function cancelReply(postId) {
  const parentIdField = document.getElementById(`parent-id-${postId}`);
  const replyIndicator = document.getElementById(`reply-indicator-${postId}`);
  const commentInput = document.querySelector(`#comment-form-${postId} .comment-input`);
  
  parentIdField.value = '';
  replyIndicator.style.display = 'none';
  commentInput.placeholder = 'Write a comment...';
}

// Toggle Replies
function toggleReplies(commentId) {
  const repliesContainer = document.getElementById(`replies-${commentId}`);
  const repliesText = document.getElementById(`replies-text-${commentId}`);
  
  if (repliesContainer.style.display === 'none' || repliesContainer.style.display === '') {
    repliesContainer.style.display = 'block';
    repliesText.textContent = 'Hide replies';
  } else {
    repliesContainer.style.display = 'none';
    const replyCount = repliesContainer.querySelectorAll('.comment-item').length;
    repliesText.textContent = `${replyCount} ${replyCount === 1 ? 'reply' : 'replies'}`;
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
