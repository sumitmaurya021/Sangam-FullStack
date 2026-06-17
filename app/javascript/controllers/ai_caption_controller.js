import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "textarea", "container"]

  connect() {
    console.log("AI Caption Controller connected")
  }

  async generate(event) {
    event.preventDefault()
    
    const btn = this.buttonTarget
    const originalText = btn.querySelector('.ai-text').innerText
    
    // Set loading state
    btn.classList.add('is-generating')
    btn.querySelector('.ai-text').innerText = 'AI is thinking...'
    this.containerTarget.classList.add('is-ai-active')
    
    try {
      const csrfToken = document.querySelector('meta[name="csrf-token"]').content
      
      const response = await fetch('/api/ai/generate_caption', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': csrfToken
        },
        body: JSON.stringify({}) // Future: send image data here
      })

      if (!response.ok) throw new Error("Failed to generate")

      const data = await response.json()
      
      // Typing effect
      this.typeText(data.caption)
      
    } catch (error) {
      console.error(error)
      alert("AI failed to generate a caption right now.")
    } finally {
      // Restore button state
      btn.classList.remove('is-generating')
      btn.querySelector('.ai-text').innerText = originalText
      
      setTimeout(() => {
        this.containerTarget.classList.remove('is-ai-active')
      }, 3000)
    }
  }

  typeText(text) {
    const textarea = this.textareaTarget
    textarea.value = ""
    let i = 0
    
    const typing = setInterval(() => {
      if (i < text.length) {
        textarea.value += text.charAt(i)
        i++
      } else {
        clearInterval(typing)
      }
    }, 20) // Adjust speed of typing here
  }
}
