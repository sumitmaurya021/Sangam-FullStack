// ╔══════════════════════════════════════════════════╗
// ║  EVENTS — RSVP (going / interested / not going) ║
// ╚══════════════════════════════════════════════════╝

window.rsvpEvent = async function(eventId, response, btn) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  btn.disabled = true;

  try {
    const res  = await fetch(`/events/${eventId}/respond_to_event`, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ response })
    });
    const data = await res.json();

    if (data.response) {
      // Update all RSVP buttons in the same card/page
      const container = btn.closest('.event-rsvp-actions') || btn.closest('.event-card-footer') || document;

      container.querySelectorAll('[onclick*="rsvpEvent"]').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      // Update counters if on detail page
      const goingEl      = document.querySelector('[id="rsvp-going"]');
      const interestedEl = document.querySelector('[id="rsvp-interested"]');
      if (goingEl && data.going_count !== undefined) {
        goingEl.classList.toggle('active', data.response === 'going');
      }
      if (interestedEl && data.interested_count !== undefined) {
        interestedEl.classList.toggle('active', data.response === 'interested');
      }

      // Update stat text if present
      const statsEl = document.querySelector('.event-rsvp-stats');
      if (statsEl && data.going_count !== undefined) {
        statsEl.innerHTML = `
          <span><strong>${data.going_count}</strong> going</span>
          <span>·</span>
          <span><strong>${data.interested_count}</strong> interested</span>
        `;
      }
    }
  } catch (e) {
    console.error('RSVP failed:', e);
  } finally {
    btn.disabled = false;
  }
};
