import { Controller } from "@hotwired/stimulus"

// Handles inline edit: replaces post card with edit form and back on cancel
export default class extends Controller {
  static values = { postId: Number }

  // Called by "Edit" button on the post card
  // data-action="click->post-edit#edit"
  edit(event) {
    event.preventDefault()
    const postId = this.postIdValue

    fetch(`/posts/${postId}/edit`, {
      headers: {
        "Accept": "text/html",
        "X-Requested-With": "XMLHttpRequest"
      }
    })
    .then(res => {
      if (!res.ok) throw new Error("Failed to load edit form")
      return res.text()
    })
    .then(html => {
      const postEl = document.getElementById(`post-${postId}`)
      if (postEl) {
        // Store original HTML so we can restore it on cancel
        postEl.dataset.originalHtml = postEl.outerHTML
        postEl.outerHTML = html
      }
    })
    .catch(err => console.error("Post edit load error:", err))
  }

  // Called by "Cancel" button inside the inline edit form
  cancel(event) {
    event.preventDefault()
    const postId = this.postIdValue
    const postEl = document.getElementById(`post-${postId}`)

    if (postEl) {
      // Fetch the fresh post card partial from server
      fetch(`/posts/${postId}`, {
        headers: {
          "Accept": "text/html",
          "X-Requested-With": "XMLHttpRequest"
        }
      })
      .then(res => {
        if (!res.ok) throw new Error("Failed to load post card")
        return res.text()
      })
      .then(html => {
        postEl.outerHTML = html
      })
      .catch(() => window.location.reload())
    }
  }
}
