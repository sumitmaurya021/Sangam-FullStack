import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "input", "parentId", "repliedToUserId", "replyIndicator", "replyToName"]
  static values = { postId: Number }

  toggleSection(event) {
    event.preventDefault()
    if (this.hasContainerTarget) {
      const isHidden = this.containerTarget.style.display === "none" || !this.containerTarget.style.display
      this.containerTarget.style.display = isHidden ? "block" : "none"
      if (isHidden && this.hasInputTarget) {
        this.inputTarget.focus()
      }
    }
  }

  replyTo(event) {
    event.preventDefault()
    const { commentId, userName, userId } = event.params

    if (this.hasParentIdTarget) this.parentIdTarget.value = commentId
    if (this.hasRepliedToUserIdTarget) this.repliedToUserIdTarget.value = userId
    if (this.hasReplyToNameTarget) this.replyToNameTarget.textContent = userName
    if (this.hasReplyIndicatorTarget) this.replyIndicatorTarget.style.display = "flex"

    if (this.hasInputTarget) {
      this.inputTarget.focus()
      this.inputTarget.placeholder = `Reply to ${userName}...`
    }
  }

  cancelReply(event) {
    if (event) event.preventDefault()

    if (this.hasParentIdTarget) this.parentIdTarget.value = ""
    if (this.hasRepliedToUserIdTarget) this.repliedToUserIdTarget.value = ""
    if (this.hasReplyIndicatorTarget) this.replyIndicatorTarget.style.display = "none"

    if (this.hasInputTarget) {
      this.inputTarget.placeholder = "Write a comment..."
    }
  }
}
