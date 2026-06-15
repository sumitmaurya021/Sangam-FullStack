import consumer from "channels/consumer";

// Heartbeat interval — ping server every 30 seconds to confirm we're active
const HEARTBEAT_INTERVAL_MS = 30_000;

export class PresenceChannel {
  constructor(chatApp) {
    this.chatApp = chatApp;
    this._subscription = null;
    this._heartbeatTimer = null;
    this._subscribe();
    this._setupVisibilityChange();
  }

  _subscribe() {
    this._subscription = consumer.subscriptions.create(
      { channel: "PresenceChannel" },
      {
        connected: () => {
          console.log("[PresenceChannel] connected");
          this._startHeartbeat();
        },
        disconnected: () => {
          this._stopHeartbeat();
        },
        received: (data) => {
          if (data.type === "presence_update") {
            this.chatApp.handlePresenceUpdate(data);
          } else if (data.type === "ping_request") {
            // Server asked us to start heartbeating
            this._startHeartbeat();
          }
        }
      }
    );
  }

  _startHeartbeat() {
    this._stopHeartbeat();
    // Send an immediate heartbeat, then every 30s
    this._sendHeartbeat();
    this._heartbeatTimer = setInterval(() => this._sendHeartbeat(), HEARTBEAT_INTERVAL_MS);
  }

  _stopHeartbeat() {
    if (this._heartbeatTimer) {
      clearInterval(this._heartbeatTimer);
      this._heartbeatTimer = null;
    }
  }

  _sendHeartbeat() {
    this._subscription?.perform("heartbeat");
  }

  // Pause heartbeat when tab is hidden, resume when visible
  _setupVisibilityChange() {
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "visible") {
        this._startHeartbeat();
      } else {
        this._stopHeartbeat();
      }
    });
  }
}
