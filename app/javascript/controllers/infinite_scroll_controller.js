import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["feed", "sentinel", "spinner", "skeleton"]
  static values = {
    url: String,
    page: Number,
    totalPages: Number,
    loading: Boolean
  }

  connect() {
    this.observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting && !this.loadingValue && this.hasMorePages()) {
            this.loadNextPage()
          }
        })
      },
      {
        rootMargin: "0px 0px 400px 0px",
        threshold: 0
      }
    )

    if (this.hasSentinelTarget) {
      this.observer.observe(this.sentinelTarget)
    }
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  hasMorePages() {
    return this.pageValue < this.totalPagesValue
  }

  async loadNextPage() {
    this.loadingValue = true
    const nextPage = this.pageValue + 1

    this.showLoaders(true)

    try {
      const response = await fetch(`${this.urlValue}?page=${nextPage}`, {
        headers: {
          "Accept": "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) throw new Error("Failed to fetch next page")

      const data = await response.json()

      if (data.posts_html) {
        const tempDiv = document.createElement("div")
        tempDiv.innerHTML = data.posts_html

        const newCards = tempDiv.querySelectorAll(".post-card")
        newCards.forEach((card, index) => {
          card.classList.add("post-fade-in")
          card.style.animationDelay = `${index * 0.1}s`
        })

        if (this.hasFeedTarget) {
          this.feedTarget.insertAdjacentHTML("beforeend", tempDiv.innerHTML)
        }
      }

      this.pageValue = nextPage
      if (data.total_pages) {
        this.totalPagesValue = data.total_pages
      }
    } catch (error) {
      console.error("Error loading next page of posts:", error)
    } finally {
      this.loadingValue = false
      this.showLoaders(false)
    }
  }

  showLoaders(show) {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.style.display = show ? "block" : "none"
    }
    if (this.hasSkeletonTarget) {
      this.skeletonTarget.style.display = show ? "block" : "none"
    }
  }
}
