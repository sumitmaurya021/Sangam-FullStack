import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["video", "playIcon", "muteIcon"]
  static values = {
    reelId: Number,
    musicUrl: String,
    muted: Boolean
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            this.play()
          } else {
            this.pause()
          }
        })
      },
      { rootMargin: "-15% 0px -15% 0px", threshold: 0.5 }
    )

    this.observer.observe(this.element)
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
    this.stopMusic()
  }

  play() {
    if (this.hasVideoTarget) {
      this.videoTarget.muted = this.hasMusicUrlValue ? true : this.mutedValue
      this.videoTarget.play().catch(() => {})
      if (this.hasPlayIconTarget) {
        this.playIconTarget.style.display = "none"
      }
    }
    if (this.hasMusicUrlValue) {
      this.playMusic()
    }
  }

  pause() {
    if (this.hasVideoTarget) {
      this.videoTarget.pause()
      if (this.hasPlayIconTarget) {
        this.playIconTarget.style.display = "flex"
      }
    }
    this.stopMusic()
  }

  togglePlay() {
    if (!this.hasVideoTarget) return
    if (this.videoTarget.paused) {
      this.play()
    } else {
      this.pause()
    }
  }

  toggleMute() {
    this.mutedValue = !this.mutedValue
    if (this.hasVideoTarget) {
      this.videoTarget.muted = this.mutedValue
    }
    if (this.musicAudio) {
      this.musicAudio.muted = this.mutedValue
    }
  }

  playMusic() {
    if (!this.hasMusicUrlValue) return
    if (!this.musicAudio) {
      this.musicAudio = new Audio(this.musicUrlValue)
      this.musicAudio.loop = true
    }
    this.musicAudio.muted = this.mutedValue
    this.musicAudio.play().catch(() => {})
  }

  stopMusic() {
    if (this.musicAudio) {
      this.musicAudio.pause()
      this.musicAudio.currentTime = 0
    }
  }
}
