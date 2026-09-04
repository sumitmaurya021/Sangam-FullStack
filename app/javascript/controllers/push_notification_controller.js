import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["toggle", "status", "testBtn", "container"]

  connect() {
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content || ""
    this.vapidPublicKey = document.querySelector('meta[name="vapid-public-key"]')?.content || ""
    this.checkSubscription()
  }

  isSupported() {
    return ("serviceWorker" in navigator) && ("PushManager" in window) && ("Notification" in window)
  }

  async checkSubscription() {
    if (!this.isSupported()) {
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = "Push notifications not supported on this browser"
      }
      if (this.hasToggleTarget) {
        this.toggleTarget.disabled = true
      }
      if (this.hasTestBtnTarget) {
        this.testBtnTarget.style.display = "none"
      }
      return
    }

    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      const isSubscribed = !(subscription === null)
      if (this.hasToggleTarget) {
        this.toggleTarget.checked = isSubscribed
      }
      if (this.hasStatusTarget) {
        this.statusTarget.textContent = isSubscribed ? "Push notifications enabled" : "Enable push notifications"
      }
      if (this.hasTestBtnTarget) {
        this.testBtnTarget.style.display = isSubscribed ? "inline-flex" : "none"
      }
    } catch (e) {
      console.warn("[PushNotifications] Failed to check status:", e)
    }
  }

  async toggle(event) {
    const isChecked = event.target.checked

    if (isChecked) {
      await this.subscribe()
    } else {
      await this.unsubscribe()
    }
  }

  async subscribe() {
    if (!this.isSupported()) {
      alert("Push notifications are not supported by your browser.")
      if (this.hasToggleTarget) this.toggleTarget.checked = false
      return
    }

    try {
      const permission = await Notification.requestPermission()
      if (permission !== "granted") {
        alert("Push notifications permission was denied. Please allow notifications in your browser address bar settings.")
        if (this.hasToggleTarget) this.toggleTarget.checked = false
        return
      }

      if (!this.vapidPublicKey) {
        console.error("[PushNotifications] Missing VAPID public key")
        return
      }

      const registration = await navigator.serviceWorker.ready
      const convertedVapidKey = this.urlBase64ToUint8Array(this.vapidPublicKey)

      const subscription = await registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: convertedVapidKey
      })

      const rawKey = subscription.getKey ? subscription.getKey("p256dh") : null
      const rawAuth = subscription.getKey ? subscription.getKey("auth") : null

      const p256dh = rawKey ? btoa(String.fromCharCode.apply(null, new Uint8Array(rawKey))) : ""
      const auth = rawAuth ? btoa(String.fromCharCode.apply(null, new Uint8Array(rawAuth))) : ""

      const response = await fetch("/push_subscriptions", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        },
        body: JSON.stringify({
          subscription: {
            endpoint: subscription.endpoint,
            keys: {
              p256dh: p256dh,
              auth: auth
            }
          }
        })
      })

      if (response.ok) {
        if (this.hasStatusTarget) this.statusTarget.textContent = "Push notifications enabled"
        if (this.hasTestBtnTarget) this.testBtnTarget.style.display = "inline-flex"
      } else {
        throw new Error("Server rejected push subscription")
      }
    } catch (error) {
      console.error("[PushNotifications] Subscribe error:", error)
      if (this.hasToggleTarget) this.toggleTarget.checked = false
      if (this.hasStatusTarget) this.statusTarget.textContent = "Failed to enable notifications"
    }
  }

  async unsubscribe() {
    try {
      const registration = await navigator.serviceWorker.ready
      const subscription = await registration.pushManager.getSubscription()

      if (subscription) {
        await fetch("/push_subscriptions", {
          method: "DELETE",
          headers: {
            "Content-Type": "application/json",
            "Accept": "application/json",
            "X-CSRF-Token": this.csrfToken
          },
          body: JSON.stringify({ endpoint: subscription.endpoint })
        })

        await subscription.unsubscribe()
      }

      if (this.hasStatusTarget) this.statusTarget.textContent = "Enable push notifications"
      if (this.hasTestBtnTarget) this.testBtnTarget.style.display = "none"
    } catch (error) {
      console.error("[PushNotifications] Unsubscribe error:", error)
    }
  }

  async test(event) {
    event.preventDefault()
    const btn = event.currentTarget
    const originalHtml = btn.innerHTML
    btn.disabled = true
    btn.innerHTML = `<span>Sending...</span>`

    try {
      const response = await fetch("/push_subscriptions/test", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
          "X-CSRF-Token": this.csrfToken
        }
      })

      const data = await response.json()
      if (response.ok) {
        btn.innerHTML = `<span>✓ Sent!</span>`
        setTimeout(() => {
          btn.innerHTML = originalHtml
          btn.disabled = false
        }, 2000)
      } else {
        alert(data.error || "Failed to send test push notification.")
        btn.innerHTML = originalHtml
        btn.disabled = false
      }
    } catch (e) {
      console.error("[PushNotifications] Test send error:", e)
      alert("Could not trigger test notification.")
      btn.innerHTML = originalHtml
      btn.disabled = false
    }
  }

  urlBase64ToUint8Array(base64String) {
    const padding = "=".repeat((4 - (base64String.length % 4)) % 4)
    const base64 = (base64String + padding)
      .replace(/-/g, "+")
      .replace(/_/g, "/")

    const rawData = window.atob(base64)
    const outputArray = new Uint8Array(rawData.length)

    for (let i = 0; i < rawData.length; ++i) {
      outputArray[i] = rawData.charCodeAt(i)
    }
    return outputArray
  }
}
