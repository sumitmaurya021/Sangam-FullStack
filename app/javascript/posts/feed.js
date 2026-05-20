// Toggle User Menu
function toggleUserMenu() {
  const dropdown = document.getElementById('userDropdown');
  dropdown.classList.toggle('show');
}

// Toggle Post Menu
function togglePostMenu(postId) {
  const dropdown = document.getElementById(`postMenu${postId}`);
  dropdown.classList.toggle('show');
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

// Image preview for post creation
document.addEventListener('DOMContentLoaded', function() {
  const fileInput = document.querySelector('.file-input');
  
  if (fileInput) {
    fileInput.addEventListener('change', function(e) {
      const file = e.target.files[0];
      if (file && file.type.startsWith('image/')) {
        const reader = new FileReader();
        
        reader.onload = function(e) {
          // Remove existing preview if any
          const existingPreview = document.querySelector('.image-preview');
          if (existingPreview) {
            existingPreview.remove();
          }
          
          // Create preview
          const preview = document.createElement('div');
          preview.className = 'image-preview';
          preview.style.cssText = `
            margin-top: 1rem;
            border-radius: 12px;
            overflow: hidden;
            position: relative;
            max-width: 300px;
          `;
          
          const img = document.createElement('img');
          img.src = e.target.result;
          img.style.cssText = `
            width: 100%;
            height: auto;
            display: block;
          `;
          
          const removeBtn = document.createElement('button');
          removeBtn.innerHTML = '✕';
          removeBtn.type = 'button';
          removeBtn.style.cssText = `
            position: absolute;
            top: 0.5rem;
            right: 0.5rem;
            width: 32px;
            height: 32px;
            border-radius: 50%;
            background: rgba(0,0,0,0.7);
            color: white;
            border: none;
            cursor: pointer;
            font-size: 1.25rem;
            display: flex;
            align-items: center;
            justify-content: center;
          `;
          
          removeBtn.addEventListener('click', function() {
            preview.remove();
            fileInput.value = '';
          });
          
          preview.appendChild(img);
          preview.appendChild(removeBtn);
          
          const postInput = document.querySelector('.post-input-wrapper');
          postInput.parentNode.insertBefore(preview, postInput.nextSibling);
        };
        
        reader.readAsDataURL(file);
      }
    });
  }
});
