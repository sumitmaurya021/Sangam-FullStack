import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "icon"]
  static values = {
    postId: Number,
    bookmarked: Boolean,
    url: String
  }

  async toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const wasBookmarked = this.bookmarkedValue
    this.bookmarkedValue = !wasBookmarked

    // Optimistic UI Update (0ms)
    this.renderState(this.bookmarkedValue)

    try {
      const response = await fetch(this.urlValue || `/posts/${this.postIdValue}/bookmark`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })

      if (!response.ok) {
        // Rollback
        this.bookmarkedValue = wasBookmarked
        this.renderState(wasBookmarked)
      }
    } catch (error) {
      console.error("Error toggling bookmark:", error)
      this.bookmarkedValue = wasBookmarked
      this.renderState(wasBookmarked)
    }
  }

  renderState(isBookmarked) {
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.toggle("active", isBookmarked)
      this.buttonTarget.dataset.bookmarked = isBookmarked.toString()
    }
  }

  showCollections(event) {
    event.preventDefault()
    if (window.showCollectionPicker && this.hasPostIdValue) {
      window.showCollectionPicker(this.postIdValue, this.element)
    }
  }
}
