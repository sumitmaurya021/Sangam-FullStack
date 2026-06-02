// ╔══════════════════════════════════════════════════╗
// ║  GROUPS — Join, Leave, Approve members          ║
// ╚══════════════════════════════════════════════════╝

window.joinGroup = async function(groupId, btn) {
  btn.disabled = true;
  btn.textContent = 'Joining...';

  try {
    const res  = await fetch(`/groups/${groupId}/join`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    });
    const data = await res.json();

    if (data.joined) {
      btn.textContent = 'Joined ✓';
      btn.className   = 'btn-view-group';
      btn.onclick     = () => window.location.href = `/groups/${groupId}`;
    } else if (data.pending) {
      btn.textContent = 'Request Sent';
      btn.className   = 'btn-pending-group';
      btn.disabled    = true;
    } else if (data.error) {
      btn.textContent = 'Join Group';
      btn.disabled    = false;
    }
  } catch (e) {
    btn.textContent = 'Join Group';
    btn.disabled    = false;
    console.error('Join group failed:', e);
  }
};

window.leaveGroup = async function(groupId, btn) {
  if (!confirm('Are you sure you want to leave this group?')) return;
  btn.disabled = true;

  try {
    const res  = await fetch(`/groups/${groupId}/leave`, {
      method: 'DELETE',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json'
      }
    });
    const data = await res.json();

    if (data.left) {
      window.location.reload();
    }
  } catch (e) {
    btn.disabled = false;
    console.error('Leave group failed:', e);
  }
};

window.approveMember = async function(groupId, userId, btn) {
  btn.disabled = true;

  try {
    const res  = await fetch(`/groups/${groupId}/approve_member`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ user_id: userId })
    });
    const data = await res.json();

    if (data.approved) {
      btn.closest('.friend-request-item')?.remove();
    }
  } catch (e) {
    btn.disabled = false;
  }
};
