import { Controller } from "@hotwired/stimulus"

const REACTION_EMOJIS = {
  like: '👍',
  love: '❤️',
  haha: '😆',
  wow: '😮',
  sad: '😢',
  angry: '😡'
}

export default class extends Controller {
  static targets = ["picker", "button", "text", "icon", "count", "summary"]
  static values = {
    postId: Number,
    liked: Boolean,
    reactionType: String,
    count: Number,
    url: String
  }

  connect() {
    this.boundClosePickers = this.closePickerOnClickOutside.bind(this)
    document.addEventListener("click", this.boundClosePickers)
  }

  disconnect() {
    document.removeEventListener("click", this.boundClosePickers)
  }

  togglePicker(event) {
    event.stopPropagation()
    if (!this.hasPickerTarget) return

    const isOpen = this.pickerTarget.classList.contains("picker-open")
    this.closeAllPickers()
    if (!isOpen) {
      this.pickerTarget.style.display = "flex"
      this.pickerTarget.style.opacity = "1"
      this.pickerTarget.style.pointerEvents = "all"
      this.pickerTarget.classList.add("picker-open")
    }
  }

  closeAllPickers() {
    if (this.hasPickerTarget) {
      this.pickerTarget.classList.remove("picker-open")
      this.pickerTarget.style.display = "none"
      this.pickerTarget.style.opacity = "0"
      this.pickerTarget.style.pointerEvents = "none"
    }
  }

  closePickerOnClickOutside(event) {
    if (this.hasPickerTarget && !this.element.contains(event.target)) {
      this.closeAllPickers()
    }
  }

  async react(event) {
    event.preventDefault()
    event.stopPropagation()

    const reactionType = event.currentTarget.dataset.reaction || 'like'
    
    // Save original state for rollback
    const wasLiked = this.likedValue
    const originalType = this.reactionTypeValue
    const originalCount = this.countValue
    const originalText = this.hasTextTarget ? this.textTarget.innerHTML : ''

    // 1. Optimistic UI Update (Instant 0ms Feedback)
    const isUnliking = (wasLiked && originalType === reactionType)
    this.likedValue = !isUnliking
    this.reactionTypeValue = isUnliking ? '' : reactionType
    this.countValue = isUnliking ? Math.max(0, originalCount - 1) : (wasLiked ? originalCount : originalCount + 1)

    this.renderOptimisticState(isUnliking, reactionType)
    this.closeAllPickers()

    // 2. Asynchronous Server Request
    try {
      const response = await fetch(this.urlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ reaction_type: reactionType })
      })

      if (response.ok) {
        const data = await response.json()
        if (this.hasCountTarget && data.likes_count !== undefined) {
          this.countTarget.textContent = data.likes_count
          this.countValue = data.likes_count
        }
        if (this.hasSummaryTarget && data.reaction_counts) {
          this.updateReactionSummary(data.reaction_counts)
        }
      } else {
        // Rollback on HTTP error
        this.rollback(wasLiked, originalType, originalCount, originalText)
      }
    } catch (error) {
      console.error("Error reacting to post:", error)
      this.rollback(wasLiked, originalType, originalCount, originalText)
    }
  }

  renderOptimisticState(isUnliking, reactionType) {
    if (this.hasButtonTarget) {
      this.buttonTarget.classList.toggle("active", !isUnliking)
    }

    if (this.hasTextTarget) {
      if (isUnliking) {
        this.textTarget.innerHTML = `Like`
        if (this.hasIconTarget) this.iconTarget.style.display = 'inline-block'
      } else {
        const emoji = REACTION_EMOJIS[reactionType] || '👍'
        const label = reactionType.charAt(0).toUpperCase() + reactionType.slice(1)
        this.textTarget.innerHTML = `${emoji} ${label}`
        if (this.hasIconTarget) this.iconTarget.style.display = 'none'
      }
    }

    if (this.hasCountTarget) {
      this.countTarget.textContent = this.countValue
    }
  }

  updateReactionSummary(reactionCounts) {
    if (!this.hasSummaryTarget) return
    this.summaryTarget.innerHTML = ''
    const entries = Object.entries(reactionCounts).slice(0, 3)
    if (entries.length === 0) {
      const span = document.createElement('span')
      span.className = 'reaction-icon like'
      span.textContent = '👍'
      this.summaryTarget.appendChild(span)
    } else {
      entries.forEach(([type, count]) => {
        const span = document.createElement('span')
        span.className = `reaction-icon ${type}`
        span.textContent = REACTION_EMOJIS[type] || '👍'
        this.summaryTarget.appendChild(span)
      })
    }
  }

  rollback(wasLiked, originalType, originalCount, originalText) {
    this.likedValue = wasLiked
    this.reactionTypeValue = originalType
    this.countValue = originalCount

    if (this.hasButtonTarget) {
      this.buttonTarget.classList.toggle("active", wasLiked)
    }
    if (this.hasTextTarget && originalText) {
      this.textTarget.innerHTML = originalText
    }
    if (this.hasCountTarget) {
      this.countTarget.textContent = originalCount
    }
  }
}
