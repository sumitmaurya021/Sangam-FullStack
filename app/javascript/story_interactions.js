// ── Story Interactions: Poll votes + Q&A replies ─────────────────

window.voteStoryPoll = async function (storyId, option) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  try {
    const resp = await fetch(`/stories/${storyId}/poll_vote`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken || '',
      },
      body: JSON.stringify({ option }),
    });
    const data = await resp.json();
    if (data.success) {
      updatePollUI(storyId, data.votes_a, data.votes_b, option);
    } else if (data.voted) {
      showStoryToast('You already voted!');
    }
  } catch (e) {
    console.error('Poll vote error', e);
  }
};

function updatePollUI(storyId, votesA, votesB, voted) {
  const total = votesA + votesB;
  const pctA  = total ? Math.round((votesA / total) * 100) : 50;
  const pctB  = 100 - pctA;

  const barA = document.getElementById(`poll-bar-a-${storyId}`);
  const barB = document.getElementById(`poll-bar-b-${storyId}`);
  const cntA = document.getElementById(`poll-count-a-${storyId}`);
  const cntB = document.getElementById(`poll-count-b-${storyId}`);

  if (barA) barA.style.width = `${pctA}%`;
  if (barB) barB.style.width = `${pctB}%`;
  if (cntA) cntA.textContent = `${pctA}%`;
  if (cntB) cntB.textContent = `${pctB}%`;

  // Highlight voted option
  const container = document.getElementById(`story-poll-${storyId}`);
  if (container) {
    container.querySelectorAll('.story-poll-option').forEach(btn => {
      btn.disabled = true;
      btn.classList.remove('voted');
    });
    const votedBtn = container.querySelector(`[data-option="${voted}"]`);
    if (votedBtn) votedBtn.classList.add('voted');
    container.classList.add('has-voted');
  }
}

window.submitStoryQA = async function (storyId, inputEl) {
  const answer = inputEl.value.trim();
  if (!answer) return;

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  try {
    const resp = await fetch(`/stories/${storyId}/qa_reply`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken || '',
      },
      body: JSON.stringify({ answer }),
    });
    const data = await resp.json();
    if (data.success) {
      inputEl.value = '';
      showStoryToast('Reply sent! 💬');
    }
  } catch (e) {
    console.error('Q&A reply error', e);
  }
};

function showStoryToast(msg) {
  const toast = document.createElement('div');
  toast.className = 'story-toast';
  toast.textContent = msg;
  document.body.appendChild(toast);
  setTimeout(() => toast.classList.add('show'), 10);
  setTimeout(() => { toast.classList.remove('show'); setTimeout(() => toast.remove(), 300); }, 2500);
}
