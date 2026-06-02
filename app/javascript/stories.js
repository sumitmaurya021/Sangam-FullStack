// ╔══════════════════════════════════════════════════════════╗
// ║  STORIES — Instagram/Facebook style 24h disappearing    ║
// ╚══════════════════════════════════════════════════════════╝

let storyGroups   = [];  // [{user, stories: [...]}]
let currentGroupIndex  = 0;
let currentStoryIndex  = 0;
let storyTimer    = null;
const STORY_DURATION = 5000; // 5s per story
const CURRENT_USER_ID = document.querySelector('meta[name="current-user-id"]')?.content;

// ── Load stories feed ───────────────────────────────────────
document.addEventListener('DOMContentLoaded', loadStoriesFeed);
document.addEventListener('turbo:load',       loadStoriesFeed);

async function loadStoriesFeed() {
  const storiesList = document.getElementById('stories-list');
  if (!storiesList) return;

  try {
    const res  = await fetch('/stories/active', { headers: { 'Accept': 'application/json' } });
    const data = await res.json();
    storyGroups = data;
    renderStoriesBar(data);
  } catch (e) {
    console.warn('Stories feed failed:', e);
  }
}

function renderStoriesBar(groups) {
  const container = document.getElementById('stories-list');
  if (!container) return;

  if (groups.length === 0) {
    container.innerHTML = '';
    return;
  }

  container.innerHTML = groups.map((group, gIndex) => {
    const user = group.user;
    const hasUnviewed = !group.all_viewed;
    const avatarHtml = user.avatar
      ? `<img src="${user.avatar}" alt="${escHtml(user.name)}" class="story-avatar-img">`
      : `<span class="story-avatar-letter">${(user.name || '?')[0].toUpperCase()}</span>`;

    return `
      <div class="story-item ${hasUnviewed ? 'has-new' : 'all-viewed'}"
           onclick="openStoryViewer(${gIndex})"
           title="${escHtml(user.name)}">
        <div class="story-avatar-ring ${hasUnviewed ? 'story-ring-active' : 'story-ring-viewed'}">
          <div class="story-avatar">${avatarHtml}</div>
        </div>
        <span class="story-name">${escHtml(user.name)}</span>
      </div>`;
  }).join('');
}

// ── Story Viewer ────────────────────────────────────────────
window.openStoryViewer = function(groupIndex) {
  currentGroupIndex = groupIndex;
  currentStoryIndex = 0;
  showCurrentStory();
  document.getElementById('storyViewerOverlay').style.display = 'flex';
  document.body.style.overflow = 'hidden';
};

window.closeStoryViewer = function(event) {
  if (event && event.target !== document.getElementById('storyViewerOverlay')) return;
  _doCloseViewer();
};

function _doCloseViewer() {
  clearStoryTimer();
  document.getElementById('storyViewerOverlay').style.display = 'none';
  document.body.style.overflow = '';
}

function showCurrentStory() {
  const group = storyGroups[currentGroupIndex];
  if (!group) { _doCloseViewer(); return; }

  const story = group.stories[currentStoryIndex];
  if (!story) { _doCloseViewer(); return; }

  clearStoryTimer();

  // Header
  const avatarEl = document.getElementById('storyViewerAvatar');
  avatarEl.innerHTML = group.user.avatar
    ? `<img src="${group.user.avatar}" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">`
    : `<span style="font-weight:700;font-size:18px;">${(group.user.name||'?')[0].toUpperCase()}</span>`;
  document.getElementById('storyViewerName').textContent  = group.user.name;
  document.getElementById('storyViewerTime').textContent  = timeAgo(story.created_at);

  // Show/hide delete btn for own stories
  const deleteBtn = document.getElementById('storyDeleteBtn');
  deleteBtn.style.display = (String(group.user.id) === String(CURRENT_USER_ID)) ? 'flex' : 'none';
  deleteBtn.dataset.storyId = story.id;

  // Media
  const img  = document.getElementById('storyViewerImg');
  const vid  = document.getElementById('storyViewerVid');
  const txt  = document.getElementById('storyViewerText');
  img.style.display = 'none';
  vid.style.display = 'none';
  txt.style.display = 'none';

  if (story.story_type === 'video' && story.media_url) {
    vid.src = story.media_url;
    vid.style.display = 'block';
    vid.play().catch(() => {});
  } else if (story.story_type === 'text') {
    txt.style.display = 'flex';
    txt.style.background = story.background_color || '#1a1a2e';
    txt.style.color      = story.text_color || '#fff';
    txt.textContent      = story.caption || '';
  } else if (story.media_url) {
    img.src = story.media_url;
    img.style.display = 'block';
  }

  // Caption
  document.getElementById('storyViewerCaption').textContent =
    (story.story_type !== 'text' && story.caption) ? story.caption : '';

  // Progress bars
  renderProgressBars(group.stories.length, currentStoryIndex);

  // Nav arrows visibility
  document.getElementById('storyNavPrev').style.display = (currentGroupIndex > 0 || currentStoryIndex > 0) ? 'flex' : 'none';
  const isLast = currentGroupIndex >= storyGroups.length - 1 && currentStoryIndex >= group.stories.length - 1;
  document.getElementById('storyNavNext').style.display = isLast ? 'none' : 'flex';

  // Mark viewed
  markStoryViewed(story.id);

  // Auto-advance
  storyTimer = setTimeout(nextStory, STORY_DURATION);
}

function renderProgressBars(total, activeIndex) {
  const container = document.getElementById('storyProgressBars');
  container.innerHTML = Array.from({ length: total }, (_, i) => `
    <div class="story-progress-bar">
      <div class="story-progress-fill ${i < activeIndex ? 'completed' : i === activeIndex ? 'active' : ''}"
           style="${i === activeIndex ? `animation-duration:${STORY_DURATION}ms` : ''}"></div>
    </div>`
  ).join('');
}

window.nextStory = function() {
  const group = storyGroups[currentGroupIndex];
  if (!group) return;

  if (currentStoryIndex < group.stories.length - 1) {
    currentStoryIndex++;
    showCurrentStory();
  } else if (currentGroupIndex < storyGroups.length - 1) {
    currentGroupIndex++;
    currentStoryIndex = 0;
    showCurrentStory();
  } else {
    _doCloseViewer();
  }
};

window.prevStory = function() {
  if (currentStoryIndex > 0) {
    currentStoryIndex--;
    showCurrentStory();
  } else if (currentGroupIndex > 0) {
    currentGroupIndex--;
    const prevGroup = storyGroups[currentGroupIndex];
    currentStoryIndex = prevGroup.stories.length - 1;
    showCurrentStory();
  }
};

function clearStoryTimer() {
  if (storyTimer) { clearTimeout(storyTimer); storyTimer = null; }
}

async function markStoryViewed(storyId) {
  try {
    await fetch(`/stories/${storyId}/view`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    });
  } catch (e) { /* silent */ }
}

window.deleteCurrentStory = async function() {
  const deleteBtn = document.getElementById('storyDeleteBtn');
  const storyId   = deleteBtn.dataset.storyId;
  if (!storyId || !confirm('Delete this story?')) return;

  try {
    await fetch(`/stories/${storyId}`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    });
    // Remove from local data
    const group = storyGroups[currentGroupIndex];
    group.stories.splice(currentStoryIndex, 1);
    if (group.stories.length === 0) {
      storyGroups.splice(currentGroupIndex, 1);
      renderStoriesBar(storyGroups);
    }
    // Move to next or close
    if (storyGroups.length === 0) {
      _doCloseViewer();
    } else {
      if (currentGroupIndex >= storyGroups.length) currentGroupIndex = storyGroups.length - 1;
      currentStoryIndex = 0;
      showCurrentStory();
    }
  } catch (e) {
    alert('Could not delete story. Try again.');
  }
};

// ── Create Story Modal ──────────────────────────────────────
window.openCreateStoryModal = function() {
  document.getElementById('createStoryOverlay').style.display = 'flex';
  document.body.style.overflow = 'hidden';
};

window.closeCreateStoryModal = function(event) {
  if (event && event.target !== document.getElementById('createStoryOverlay')) return;
  document.getElementById('createStoryOverlay').style.display = 'none';
  document.body.style.overflow = '';
};

window.switchStoryTab = function(type, btn) {
  document.querySelectorAll('.story-tab').forEach(t => t.classList.remove('active'));
  btn.classList.add('active');
  document.getElementById('story-type-input').value = type;

  const mediaSection   = document.getElementById('story-media-section');
  const textSection    = document.getElementById('story-text-section');
  const captionSection = document.getElementById('story-caption-section');

  if (type === 'text') {
    mediaSection.style.display   = 'none';
    textSection.style.display    = 'block';
    captionSection.style.display = 'none';
  } else {
    mediaSection.style.display   = 'block';
    textSection.style.display    = 'none';
    captionSection.style.display = 'block';
    document.getElementById('story-media-input').accept = type === 'video' ? 'video/*' : 'image/*';
  }
};

window.previewStoryMedia = function(input) {
  const file = input.files[0];
  if (!file) return;

  const img = document.getElementById('storyImagePreviewImg');
  const vid = document.getElementById('storyVideoPreviewVid');
  const placeholder = document.querySelector('.story-upload-preview');
  const url = URL.createObjectURL(file);

  if (file.type.startsWith('video/')) {
    vid.src = url;
    vid.style.display = 'block';
    img.style.display = 'none';
    placeholder.style.display = 'none';
  } else {
    img.src = url;
    img.style.display = 'block';
    vid.style.display = 'none';
    placeholder.style.display = 'none';
  }
};

window.setStoryBg = function(color) {
  document.getElementById('story-bg-color').value = color;
  document.getElementById('storyTextPreview').style.background = color;
};

window.updateStoryTextPreview = function(text) {
  // The textarea itself acts as the preview — nothing extra needed
};

// ── Utils ───────────────────────────────────────────────────
function escHtml(str) {
  const div = document.createElement('div');
  div.textContent = str || '';
  return div.innerHTML;
}

function timeAgo(isoStr) {
  const seconds = Math.floor((Date.now() - new Date(isoStr)) / 1000);
  if (seconds < 60) return `${seconds}s ago`;
  if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
  return `${Math.floor(seconds / 3600)}h ago`;
}
