// Facebook-Style Reaction Picker

document.addEventListener('DOMContentLoaded', function() {
  // Initialize reaction pickers
  initializeReactionPickers();
});

function initializeReactionPickers() {
  const reactionWrappers = document.querySelectorAll('.reaction-picker-wrapper');
  
  reactionWrappers.forEach(wrapper => {
    const postId = wrapper.dataset.postId;
    const trigger = wrapper.querySelector('.reaction-trigger');
    const reactionBar = wrapper.querySelector('.reaction-bar');
    const reactionBtns = wrapper.querySelectorAll('.reaction-btn');
    
    // Show reaction bar on hover
    trigger.addEventListener('mouseenter', () => {
      reactionBar.classList.add('show');
    });
    
    // Keep showing when hovering over reaction bar
    reactionBar.addEventListener('mouseenter', () => {
      reactionBar.classList.add('show');
    });
    
    // Hide when leaving
    trigger.addEventListener('mouseleave', () => {
      setTimeout(() => {
        if (!reactionBar.matches(':hover')) {
          reactionBar.classList.remove('show');
        }
      }, 100);
    });
    
    reactionBar.addEventListener('mouseleave', () => {
      reactionBar.classList.remove('show');
    });
    
    // Handle reaction selection
    reactionBtns.forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.preventDefault();
        const reaction = btn.dataset.reaction;
        submitReaction(postId, reaction, trigger, reactionBar);
      });
    });
    
    // Handle main button click (default like)
    trigger.addEventListener('click', (e) => {
      if (!trigger.classList.contains('has-reaction')) {
        e.preventDefault();
        submitReaction(postId, 'like', trigger, reactionBar);
      }
    });
  });
}

function submitReaction(postId, reactionType, triggerBtn, reactionBar) {
  // Show loading state
  triggerBtn.style.opacity = '0.6';
  
  // Make AJAX request
  fetch(`/posts/${postId}/reactions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
    },
    body: JSON.stringify({ reaction: reactionType })
  })
  .then(response => response.json())
  .then(data => {
    // Update UI
    updateReactionUI(postId, reactionType, data.likes_count, triggerBtn);
    
    // Hide reaction bar
    reactionBar.classList.remove('show');
    
    // Show animation
    showReactionAnimation(reactionType, triggerBtn);
  })
  .catch(error => {
    console.error('Error:', error);
    // Revert loading state
    triggerBtn.style.opacity = '1';
  });
}

function updateReactionUI(postId, reactionType, likesCount, triggerBtn) {
  // Update likes count
  const likesCountEl = document.getElementById(`likes-count-${postId}`);
  if (likesCountEl) {
    likesCountEl.textContent = likesCount;
  }
  
  // Update reactions display
  const reactionsDisplay = document.getElementById(`reactions-${postId}`);
  if (reactionsDisplay) {
    const reactionIcons = {
      like: '👍',
      love: '❤️',
      haha: '😂',
      wow: '😮',
      sad: '😢',
      angry: '😠'
    };
    
    reactionsDisplay.innerHTML = `<span class="reaction-icon ${reactionType}">${reactionIcons[reactionType]}</span>`;
  }
  
  // Update trigger button
  triggerBtn.classList.add('has-reaction', 'active');
  triggerBtn.classList.add(`reaction-${reactionType}`);
  
  // Update button content based on reaction
  const reactionLabels = {
    like: 'Like',
    love: 'Love',
    haha: 'Haha',
    wow: 'Wow',
    sad: 'Sad',
    angry: 'Angry'
  };
  
  const actionText = triggerBtn.querySelector('.action-text');
  if (actionText) {
    actionText.textContent = reactionLabels[reactionType];
  }
  
  triggerBtn.style.opacity = '1';
}

function showReactionAnimation(reactionType, triggerBtn) {
  // Create floating reaction element
  const rect = triggerBtn.getBoundingClientRect();
  const floatEl = document.createElement('div');
  floatEl.textContent = getReactionEmoji(reactionType);
  floatEl.style.cssText = `
    position: fixed;
    left: ${rect.left + rect.width / 2}px;
    top: ${rect.top}px;
    font-size: 3rem;
    pointer-events: none;
    z-index: 10000;
    animation: floatReaction 1s ease-out forwards;
  `;
  
  document.body.appendChild(floatEl);
  
  setTimeout(() => {
    floatEl.remove();
  }, 1000);
}

function getReactionEmoji(reactionType) {
  const emojis = {
    like: '👍',
    love: '❤️',
    haha: '😂',
    wow: '😮',
    sad: '😢',
    angry: '😠'
  };
  return emojis[reactionType] || '👍';
}

// Add CSS for floating animation
const style = document.createElement('style');
style.textContent = `
  @keyframes floatReaction {
    0% {
      opacity: 1;
      transform: translate(-50%, 0) scale(0.5);
    }
    50% {
      opacity: 1;
      transform: translate(-50%, -50px) scale(1.2);
    }
    100% {
      opacity: 0;
      transform: translate(-50%, -100px) scale(0.8);
    }
  }
`;
document.head.appendChild(style);
