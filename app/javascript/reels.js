// =====================================================
// REELS — Simple like/unlike + Jamendo music + hashtags
// =====================================================

// ── State ─────────────────────────────────────────────
let currentReelId  = null;
let mutedState     = {};
let reelObserver   = null;
let musicAudio     = null;       // preview audio in upload modal
let reelMusicAudios = {};        // per-reel background music: { reelId: Audio }
let musicDebounceTimer = null;
let hashtagList    = [];
let selectedMusic  = null;
let selectedVideoFile = null;

// ── Intersection Observer (auto-play) ─────────────────
function initReelObserver() {
  reelObserver = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      const reelId = entry.target.dataset.reelId;
      const video  = document.getElementById(`reel-video-${reelId}`);
      if (!video) return;

      if (entry.isIntersecting) {
        // Pause all other videos + their music
        document.querySelectorAll('.reel-card').forEach(card => {
          const otherId = card.dataset.reelId;
          if (otherId === reelId) return;
          const otherVideo = document.getElementById(`reel-video-${otherId}`);
          if (otherVideo) { otherVideo.pause(); showPlayIcon(otherId); }
          stopReelMusic(otherId);
        });

        const hasMusicUrl = entry.target.dataset.musicUrl;

        // Video: always muted if music is added, else respect mutedState
        video.muted = hasMusicUrl ? true : (mutedState[reelId] !== false);
        video.play().catch(() => {});
        hidePlayIcon(reelId);
        trackView(reelId);

        // Play background music if this reel has music
        if (hasMusicUrl) {
          playReelMusic(reelId, hasMusicUrl);
        } else {
          // No music — show unmuted icon if video is unmuted
          if (!video.muted) {
            const icon = document.getElementById(`mute-icon-${reelId}`);
            if (icon) icon.innerHTML = '<path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>';
          }
        }
      } else {
        video.pause();
        showPlayIcon(reelId);
        stopReelMusic(reelId);
      }
    });
  }, { rootMargin: '-15% 0px -15% 0px', threshold: 0.5 });

  document.querySelectorAll('.reel-card').forEach(c => reelObserver.observe(c));
}

// ── Play / Pause ───────────────────────────────────────
function togglePlay(reelId) {
  const video = document.getElementById(`reel-video-${reelId}`);
  if (!video) return;
  const card = document.getElementById(`reel-${reelId}`);
  const musicUrl = card?.dataset.musicUrl;

  if (video.paused) {
    video.play().catch(() => {});
    hidePlayIcon(reelId);
    playReelMusic(reelId, musicUrl);
  } else {
    video.pause();
    showPlayIcon(reelId);
    stopReelMusic(reelId);
  }
}

function showPlayIcon(reelId) {
  const el = document.getElementById(`play-icon-${reelId}`);
  if (el) el.classList.add('show');
}
function hidePlayIcon(reelId) {
  const el = document.getElementById(`play-icon-${reelId}`);
  if (el) { el.classList.remove('show'); }
}

// ── Mute ──────────────────────────────────────────────
function toggleMute(reelId) {
  const icon  = document.getElementById(`mute-icon-${reelId}`);
  const video = document.getElementById(`reel-video-${reelId}`);
  const bgMusic = reelMusicAudios[reelId];
  const card  = document.getElementById(`reel-${reelId}`);
  const hasMusicUrl = card?.dataset.musicUrl;

  // If reel has added music — toggle music audio
  // If no added music — toggle video audio
  if (hasMusicUrl && bgMusic) {
    bgMusic.muted = !bgMusic.muted;
    mutedState[reelId] = bgMusic.muted;
    if (icon) {
      icon.innerHTML = bgMusic.muted
        ? '<path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>'
        : '<path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>';
    }
  } else if (video) {
    // No added music — toggle video's own audio
    video.muted = !video.muted;
    mutedState[reelId] = video.muted;
    if (icon) {
      icon.innerHTML = video.muted
        ? '<path d="M3 9v6h4l5 5V4L7 9H3zm13.5 3c0-1.77-1.02-3.29-2.5-4.03v8.05c1.48-.73 2.5-2.25 2.5-4.02zM14 3.23v2.06c2.89.86 5 3.54 5 6.71s-2.11 5.85-5 6.71v2.06c4.01-.91 7-4.49 7-8.77s-2.99-7.86-7-8.77z"/>'
        : '<path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>';
    }
  }
}

// ── Reel background music ──────────────────────────────
function playReelMusic(reelId, musicUrl) {
  if (!musicUrl) return;
  stopReelMusic(reelId);

  const audio = new Audio(musicUrl);
  audio.loop   = true;
  audio.volume = 0.75;
  audio.muted  = false; // music starts unmuted
  audio.play().catch(() => {});
  reelMusicAudios[reelId] = audio;

  // Update mute icon to show unmuted (since music is playing)
  const icon = document.getElementById(`mute-icon-${reelId}`);
  if (icon) {
    icon.innerHTML = '<path d="M16.5 12c0-1.77-1.02-3.29-2.5-4.03v2.21l2.45 2.45c.03-.2.05-.41.05-.63zm2.5 0c0 .94-.2 1.82-.54 2.64l1.51 1.51C20.63 14.91 21 13.5 21 12c0-4.28-2.99-7.86-7-8.77v2.06c2.89.86 5 3.54 5 6.71zM4.27 3L3 4.27 7.73 9H3v6h4l5 5v-6.73l4.25 4.25c-.67.52-1.42.93-2.25 1.18v2.06c1.38-.31 2.63-.95 3.69-1.81L19.73 21 21 19.73l-9-9L4.27 3zM12 4L9.91 6.09 12 8.18V4z"/>';
  }
  mutedState[reelId] = false;

  const disc = document.getElementById(`music-disc-${reelId}`);
  if (disc) disc.style.animationPlayState = 'running';
}

function stopReelMusic(reelId) {
  const audio = reelMusicAudios[reelId];
  if (audio) {
    audio.pause();
    audio.src = '';
    delete reelMusicAudios[reelId];
  }
  const disc = document.getElementById(`music-disc-${reelId}`);
  if (disc) disc.style.animationPlayState = 'paused';
}

// ── Progress bars ──────────────────────────────────────
function initProgressBars() {
  document.querySelectorAll('.reel-video').forEach(video => {
    const id = video.id.replace('reel-video-', '');
    video.addEventListener('timeupdate', () => {
      if (!video.duration) return;
      const bar = document.getElementById(`progress-${id}`);
      if (bar) bar.style.width = (video.currentTime / video.duration * 100) + '%';
    });
  });
}

// ── View tracking ──────────────────────────────────────
const viewedReels = new Set();
function trackView(reelId) {
  if (viewedReels.has(reelId)) return;
  viewedReels.add(reelId);
  fetch(`/reels/${reelId}/view`, {
    method: 'POST',
    headers: { 'X-CSRF-Token': window.csrfToken, 'Accept': 'application/json' }
  }).then(r => r.json()).then(d => {
    const el = document.getElementById(`views-count-${reelId}`);
    if (el && d.views_count !== undefined) el.textContent = fmtCount(d.views_count);
  }).catch(() => {});
}

// ── Like / Unlike (simple toggle) ─────────────────────
function toggleLike(reelId) {
  const btn = document.getElementById(`like-btn-${reelId}`);
  const isLiked = btn && btn.classList.contains('liked');

  fetch(`/reels/${reelId}/${isLiked ? 'unlike' : 'like'}`, {
    method: isLiked ? 'DELETE' : 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': window.csrfToken,
      'Accept': 'application/json'
    },
    body: isLiked ? null : JSON.stringify({ reaction_type: 'like' })
  })
  .then(r => r.json())
  .then(data => {
    if (data.success || data.likes_count !== undefined) {
      if (btn) btn.classList.toggle('liked', !isLiked);
      const countEl = document.getElementById(`likes-count-${reelId}`);
      if (countEl && data.likes_count !== undefined) countEl.textContent = fmtCount(data.likes_count);
    }
  })
  .catch(() => {});
}

// ── Comments panel ─────────────────────────────────────
function openCommentsPanel(reelId) {
  currentReelId = reelId;
  document.getElementById('commentsPanel')?.classList.add('show');
  document.getElementById('commentsOverlay')?.classList.add('show');
  loadComments(reelId);
  setTimeout(() => document.getElementById('commentInput')?.focus(), 300);
}
function closeCommentsPanel() {
  document.getElementById('commentsPanel')?.classList.remove('show');
  document.getElementById('commentsOverlay')?.classList.remove('show');
  currentReelId = null;
}

function loadComments(reelId) {
  const list = document.getElementById('commentsList');
  if (!list) return;
  list.innerHTML = '<div class="reel-comments-loading"><div class="reel-spinner"></div></div>';
  fetch(`/reels/${reelId}/reel_comments`, { headers: { 'Accept': 'application/json' } })
    .then(r => r.json())
    .then(d => renderComments(d.comments || []))
    .catch(() => { list.innerHTML = '<div class="reel-comments-empty"><p>Could not load comments.</p></div>'; });
}

function renderComments(comments) {
  const list = document.getElementById('commentsList');
  if (!list) return;
  if (!comments.length) {
    list.innerHTML = `<div class="reel-comments-empty">
      <svg width="44" height="44" viewBox="0 0 24 24" fill="currentColor"><path d="M21.99 4c0-1.1-.89-2-1.99-2H4c-1.1 0-2 .9-2 2v12c0 1.1.9 2 2 2h14l4 4-.01-18z"/></svg>
      <p>No comments yet. Be the first!</p></div>`;
    return;
  }
  list.innerHTML = comments.map(buildCommentHTML).join('');
}

function buildCommentHTML(c) {
  const av = c.user.avatar
    ? `<img src="${c.user.avatar}" alt="${esc(c.user.name)}">`
    : c.user.name[0].toUpperCase();
  const del = c.user.id === window.currentUserId
    ? `<button class="reel-comment-del" onclick="deleteComment(${c.id})">Delete</button>` : '';
  return `<div class="reel-comment-item" id="comment-${c.id}">
    <div class="reel-comment-avatar">${av}</div>
    <div class="reel-comment-body">
      <div class="reel-comment-bubble">
        <div class="reel-comment-user">${esc(c.user.name)}</div>
        <div class="reel-comment-text">${esc(c.content)}</div>
      </div>
      <div class="reel-comment-meta">
        <span class="reel-comment-time">${timeAgo(c.created_at)}</span>${del}
      </div>
    </div></div>`;
}

function submitComment() {
  if (!currentReelId) return;
  const input = document.getElementById('commentInput');
  const content = input?.value.trim();
  if (!content) return;
  const sendBtn = document.getElementById('commentSendBtn');
  if (sendBtn) sendBtn.disabled = true;

  fetch(`/reels/${currentReelId}/reel_comments`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': window.csrfToken, 'Accept': 'application/json' },
    body: JSON.stringify({ reel_comment: { content } })
  })
  .then(r => r.json())
  .then(data => {
    if (data.success) {
      if (input) input.value = '';
      const list = document.getElementById('commentsList');
      list?.querySelector('.reel-comments-empty')?.remove();
      list?.insertAdjacentHTML('beforeend', buildCommentHTML(data.comment));
      list?.lastElementChild?.scrollIntoView({ behavior: 'smooth' });
      const cnt = document.getElementById(`comments-count-${currentReelId}`);
      if (cnt) cnt.textContent = fmtCount((parseInt(cnt.textContent.replace(/\D/g,''))||0)+1);
    }
  })
  .catch(() => {})
  .finally(() => { if (sendBtn) sendBtn.disabled = false; });
}

function deleteComment(id) {
  if (!currentReelId) return;
  fetch(`/reels/${currentReelId}/reel_comments/${id}`, {
    method: 'DELETE',
    headers: { 'X-CSRF-Token': window.csrfToken, 'Accept': 'application/json' }
  }).then(r => r.json()).then(d => {
    if (d.success) {
      document.getElementById(`comment-${id}`)?.remove();
      const cnt = document.getElementById(`comments-count-${currentReelId}`);
      if (cnt) cnt.textContent = fmtCount(Math.max(0,(parseInt(cnt.textContent.replace(/\D/g,''))||0)-1));
    }
  }).catch(() => {});
}

// ── Upload Modal ───────────────────────────────────────
function openUploadModal() {
  document.getElementById('uploadModalOverlay')?.classList.add('show');
  document.body.style.overflow = 'hidden';
  showStep('stepPick');
}
function closeUploadModal() {
  document.getElementById('uploadModalOverlay')?.classList.remove('show');
  document.body.style.overflow = '';
  resetUploadForm();
}
function showStep(id) {
  ['stepPick','stepDetails'].forEach(s => {
    const el = document.getElementById(s);
    if (el) el.style.display = s === id ? 'block' : 'none';
  });

  // When details step shown, attach music input listener
  if (id === 'stepDetails') {
    const musicInput = document.getElementById('musicSearchInput');
    if (musicInput && !musicInput.dataset.listenerAttached) {
      musicInput.addEventListener('input', function() {
        searchMusicDebounced(this.value);
      });
      musicInput.dataset.listenerAttached = 'true';
    }
  }
}
function goBackToPick() { showStep('stepPick'); }

function handleVideoSelect(input) {
  const file = input.files[0];
  if (!file) return;
  selectedVideoFile = file;

  const preview = document.getElementById('previewVideo');
  const label   = document.getElementById('previewLabel');
  if (preview) { preview.src = URL.createObjectURL(file); preview.load(); }
  if (label)   label.textContent = `${file.name} · ${(file.size/1024/1024).toFixed(1)} MB`;

  // Copy file to hidden input for form submission
  const hidden = document.getElementById('videoHiddenInput');
  if (hidden) {
    const dt = new DataTransfer();
    dt.items.add(file);
    hidden.files = dt.files;
  }

  showStep('stepDetails');
}

function updateCaptionCount(el) {
  const cnt = document.getElementById('captionCount');
  if (cnt) cnt.textContent = `${el.value.length} / 2200`;
}

function resetUploadForm() {
  selectedVideoFile = null;
  selectedMusic = null;
  hashtagList = [];
  const form = document.getElementById('reelUploadForm');
  if (form) form.reset();
  document.getElementById('hashtagChips').innerHTML = '';
  document.getElementById('hashtagsHidden').value = '';
  document.getElementById('musicResults').innerHTML = '';
  document.getElementById('musicSelected').style.display = 'none';
  document.getElementById('musicSearchInput').value = '';
  document.getElementById('captionCount').textContent = '0 / 2200';
  clearMusicHidden();
  stopMusicPreview();
  showStep('stepPick');
}

// Drag & drop
function initDropzone() {
  const dz = document.getElementById('reelDropzone');
  if (!dz) return;
  dz.addEventListener('dragover', e => { e.preventDefault(); dz.classList.add('drag-over'); });
  dz.addEventListener('dragleave', () => dz.classList.remove('drag-over'));
  dz.addEventListener('drop', e => {
    e.preventDefault(); dz.classList.remove('drag-over');
    const f = e.dataTransfer.files[0];
    if (f && f.type.startsWith('video/')) {
      const inp = document.getElementById('reelVideoInput');
      const dt = new DataTransfer(); dt.items.add(f); inp.files = dt.files;
      handleVideoSelect(inp);
    }
  });
}

// Form submit with XHR progress
function initUploadForm() {
  const form = document.getElementById('reelUploadForm');
  if (!form) return;

  form.addEventListener('submit', e => {
    e.preventDefault();
    const submitBtn   = document.getElementById('reelSubmitBtn');
    const progressDiv = document.getElementById('uploadProgress');
    const fill        = document.getElementById('progressFill');
    const text        = document.getElementById('progressText');

    if (submitBtn) submitBtn.disabled = true;
    if (progressDiv) progressDiv.style.display = 'block';

    const fd = new FormData(form);
    const xhr = new XMLHttpRequest();

    xhr.upload.addEventListener('progress', ev => {
      if (!ev.lengthComputable) return;
      const pct = Math.round(ev.loaded / ev.total * 100);
      if (fill) fill.style.width = pct + '%';
      if (text) text.textContent = `Uploading... ${pct}%`;
    });
    xhr.addEventListener('load', () => {
      if (xhr.status >= 200 && xhr.status < 400) {
        if (text) text.textContent = 'Upload complete! Redirecting...';
        setTimeout(() => { window.location.href = '/reels'; }, 700);
      } else {
        if (text) text.textContent = 'Upload failed. Please try again.';
        if (submitBtn) submitBtn.disabled = false;
      }
    });
    xhr.addEventListener('error', () => {
      if (text) text.textContent = 'Upload failed. Please try again.';
      if (submitBtn) submitBtn.disabled = false;
    });
    xhr.open('POST', form.action || '/reels');
    xhr.setRequestHeader('X-CSRF-Token', window.csrfToken);
    xhr.send(fd);
  });
}

// ── Hashtags ───────────────────────────────────────────
function handleHashtagKey(e) {
  if (e.key === 'Enter' || e.key === ',' || e.key === ' ') {
    e.preventDefault();
    addHashtag(e.target.value.trim().replace(/^#+/, ''));
    e.target.value = '';
  }
}

function addHashtag(tag) {
  tag = tag.replace(/[^a-zA-Z0-9_\u0900-\u097F]/g, '').trim();
  if (!tag || hashtagList.includes(tag) || hashtagList.length >= 30) return;
  hashtagList.push(tag);
  renderHashtagChips();
  updateHashtagsHidden();
}

function removeHashtag(tag) {
  hashtagList = hashtagList.filter(t => t !== tag);
  renderHashtagChips();
  updateHashtagsHidden();
}

function renderHashtagChips() {
  const container = document.getElementById('hashtagChips');
  if (!container) return;
  container.innerHTML = hashtagList.map(t => `
    <span class="reel-chip">
      #${esc(t)}
      <button type="button" class="reel-chip-remove" onclick="removeHashtag('${esc(t)}')" title="Remove">×</button>
    </span>`).join('');
}

function updateHashtagsHidden() {
  const h = document.getElementById('hashtagsHidden');
  if (h) h.value = hashtagList.join(',');
}

// ── Music — iTunes Search API via Rails proxy ─────────────────────────────────
function searchMusicDebounced(query) {
  clearTimeout(musicDebounceTimer);
  const spinner = document.getElementById('musicSpinner');
  const results = document.getElementById('musicResults');

  if (!query || query.trim().length < 2) {
    if (results) results.innerHTML = '';
    if (spinner) spinner.style.display = 'none';
    return;
  }

  if (spinner) spinner.style.display = 'flex';
  musicDebounceTimer = setTimeout(() => searchMusic(query.trim()), 450);
}

function searchMusic(query) {
  const spinner = document.getElementById('musicSpinner');
  const results = document.getElementById('musicResults');

  // Get fresh CSRF token every time
  const csrf = document.querySelector('meta[name="csrf-token"]')?.content || '';

  fetch(`/music/search?q=${encodeURIComponent(query)}`, {
    method: 'GET',
    headers: {
      'Accept': 'application/json',
      'X-CSRF-Token': csrf,
      'X-Requested-With': 'XMLHttpRequest'
    },
    credentials: 'same-origin'
  })
  .then(r => {
    if (!r.ok) throw new Error(`HTTP ${r.status}`);
    return r.json();
  })
  .then(data => {
    if (spinner) spinner.style.display = 'none';
    renderMusicResults(data.tracks || []);
  })
  .catch(err => {
    console.error('Music search error:', err);
    if (spinner) spinner.style.display = 'none';
    if (results) results.innerHTML = `<div style="padding:16px;text-align:center;color:#ff6b6b;font-size:13px;">Search failed: ${err.message}. Try again.</div>`;
  });
}

function renderMusicResults(tracks) {
  const results = document.getElementById('musicResults');
  if (!results) return;

  if (!tracks.length) {
    results.innerHTML = `<div style="padding:16px;text-align:center;color:#8b8fa3;font-size:13px;">No songs found. Try another search.</div>`;
    return;
  }

  results.innerHTML = tracks.map(t => {
    const thumb = t.cover
      ? `<img src="${t.cover}" class="reel-music-thumb" alt="${esc(t.title)}">`
      : `<div class="reel-music-thumb-placeholder"><svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor"><path d="M12 3v10.55c-.59-.34-1.27-.55-2-.55-2.21 0-4 1.79-4 4s1.79 4 4 4 4-1.79 4-4V7h4V3h-6z"/></svg></div>`;
    const dur = t.duration ? `${Math.floor(t.duration/60)}:${String(t.duration%60).padStart(2,'0')}` : '';
    const previewSafe = esc(t.preview || '');
    return `
      <div class="reel-music-item" onclick="selectMusic('${esc(t.title)}','${esc(t.artist)}','${previewSafe}')">
        ${thumb}
        <div class="reel-music-info">
          <div class="reel-music-name">${esc(t.title)}</div>
          <div class="reel-music-artist-name">${esc(t.artist)}${dur ? ' · '+dur : ''}</div>
        </div>
        ${previewSafe ? `
        <button type="button" class="reel-music-play-btn" id="play-music-${t.id}"
                onclick="event.stopPropagation(); previewMusic('${previewSafe}','${t.id}')"
                title="Preview 30s">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>
        </button>` : ''}
      </div>`;
  }).join('');
}

function previewMusic(url, trackId) {
  stopMusicPreview();
  if (!url) return;
  musicAudio = new Audio(url);
  musicAudio.volume = 0.7;
  musicAudio.play().catch(() => {});
  const btn = document.getElementById(`play-music-${trackId}`);
  if (btn) {
    btn.classList.add('playing');
    btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/></svg>';
    musicAudio.onended = () => {
      btn.classList.remove('playing');
      btn.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
    };
  }
}

function stopMusicPreview() {
  if (musicAudio) { musicAudio.pause(); musicAudio = null; }
  document.querySelectorAll('.reel-music-play-btn.playing').forEach(b => {
    b.classList.remove('playing');
    b.innerHTML = '<svg width="14" height="14" viewBox="0 0 24 24" fill="currentColor"><path d="M8 5v14l11-7z"/></svg>';
  });
}

function selectMusic(title, artist, previewUrl) {
  stopMusicPreview();
  selectedMusic = { title, artist, previewUrl };
  document.getElementById('musicTitleHidden').value   = title;
  document.getElementById('musicArtistHidden').value  = artist;
  document.getElementById('musicPreviewHidden').value = previewUrl;
  document.getElementById('selectedMusicTitle').textContent  = title;
  document.getElementById('selectedMusicArtist').textContent = artist;
  document.getElementById('musicSelected').style.display = 'flex';
  document.getElementById('musicResults').innerHTML = '';
  document.getElementById('musicSearchInput').value = '';
}

function removeMusic() {
  selectedMusic = null;
  clearMusicHidden();
  document.getElementById('musicSelected').style.display = 'none';
}

function clearMusicHidden() {
  ['musicTitleHidden','musicArtistHidden','musicPreviewHidden'].forEach(id => {
    const el = document.getElementById(id);
    if (el) el.value = '';
  });
}

// ── Share ──────────────────────────────────────────────
function shareReel(reelId) {
  const url = `${location.origin}/reels#reel-${reelId}`;
  if (navigator.share) {
    navigator.share({ title: 'Check out this reel on Sangam!', url }).catch(() => {});
  } else {
    navigator.clipboard.writeText(url).then(() => showToast('Link copied!')).catch(() => {});
  }
}

// ── Reel menu ──────────────────────────────────────────
function toggleReelMenu(reelId) {
  const menu = document.getElementById(`reel-menu-${reelId}`);
  document.querySelectorAll('.reel-menu').forEach(m => { if (m !== menu) m.classList.remove('show'); });
  menu?.classList.toggle('show');
}

// ── Caption expand ─────────────────────────────────────
function toggleCaption(reelId, fullText) {
  const el  = document.getElementById(`caption-text-${reelId}`);
  const btn = document.getElementById(`caption-more-${reelId}`);
  if (!el) return;
  if (btn && btn.textContent === '...more') {
    el.textContent = fullText;
    if (btn) btn.textContent = ' less';
  } else {
    el.textContent = fullText.substring(0, 80);
    if (btn) btn.textContent = '...more';
  }
}

// ── Infinite scroll sentinel ───────────────────────────
function initInfiniteScroll() {
  const sentinel = document.getElementById('reelsSentinel');
  if (!sentinel) return;
  const io = new IntersectionObserver(entries => {
    if (entries[0].isIntersecting) {
      const nextPage = sentinel.dataset.nextPage;
      if (nextPage) { io.disconnect(); loadMoreReels(parseInt(nextPage)); }
    }
  }, { rootMargin: '200px' });
  io.observe(sentinel);
}

function loadMoreReels(page) {
  fetch(`/reels?page=${page}`, { headers: { 'Accept': 'application/json' } })
    .then(r => r.json())
    .then(data => {
      // Reload page to show new reels (simplest approach with server-rendered partials)
      window.location.href = `/reels?page=${page}`;
    })
    .catch(() => {});
}

// ── Toast ──────────────────────────────────────────────
function showToast(msg) {
  const t = document.createElement('div');
  t.style.cssText = 'position:fixed;bottom:24px;left:50%;transform:translateX(-50%);background:rgba(18,18,28,0.97);color:#fff;padding:11px 22px;border-radius:22px;font-size:13px;font-weight:600;z-index:9999;border:1px solid rgba(102,126,234,0.3);backdrop-filter:blur(12px);box-shadow:0 6px 24px rgba(0,0,0,0.4);animation:toastIn 0.25s ease-out;';
  t.textContent = msg;
  document.body.appendChild(t);
  setTimeout(() => t.remove(), 2800);
}

// ── Helpers ────────────────────────────────────────────
function fmtCount(n) {
  if (n >= 1e6) return (n/1e6).toFixed(1)+'M';
  if (n >= 1e3) return (n/1e3).toFixed(1)+'K';
  return String(n);
}
function esc(s) {
  if (!s) return '';
  return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}
function timeAgo(iso) {
  const d = (Date.now() - new Date(iso)) / 1000;
  if (d < 60) return 'just now';
  if (d < 3600) return Math.floor(d/60)+'m ago';
  if (d < 86400) return Math.floor(d/3600)+'h ago';
  return Math.floor(d/86400)+'d ago';
}

// ── Close menus on outside click ──────────────────────
document.addEventListener('click', e => {
  if (!e.target.closest('.reel-action-item')) {
    document.querySelectorAll('.reel-menu').forEach(m => m.classList.remove('show'));
  }
});

// ── Init ──────────────────────────────────────────────
function initReels() {
  if (!document.querySelector('.reels-page')) return;
  initReelObserver();
  initProgressBars();
  initDropzone();
  initUploadForm();
  initInfiniteScroll();
}

// ── Exports ────────────────────────────────────────────
Object.assign(window, {
  togglePlay, toggleMute, toggleLike,
  openCommentsPanel, closeCommentsPanel, submitComment, deleteComment,
  openUploadModal, closeUploadModal, goBackToPick,
  handleVideoSelect, updateCaptionCount,
  handleHashtagKey, removeHashtag,
  searchMusicDebounced, selectMusic, removeMusic, previewMusic,
  shareReel, toggleReelMenu, toggleCaption, loadMoreReels,
  playReelMusic, stopReelMusic
});

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initReels);
} else {
  initReels();
}
