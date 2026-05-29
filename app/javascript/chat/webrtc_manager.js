export class WebRTCManager {
  constructor(chatApp) {
    this.chatApp = chatApp;
    this.peerConnection = null;
    this.localStream = null;
    this.remoteStream = null;
    this.callType = null;
    this.isCaller = false;
    this.isMuted = false;
    this.isVideoOff = false;
    this.pendingOffer = null;

    // Build ICE server config from meta tags (set by Rails from ENV)
    this.iceServers = this._buildIceServers();
  }

  _buildIceServers() {
    const servers = [
      { urls: "stun:stun.l.google.com:19302" },
      { urls: "stun:stun1.l.google.com:19302" },
      { urls: "stun:stun2.l.google.com:19302" }
    ];

    // Add TURN server if configured
    const turnUrl        = document.querySelector('meta[name="turn-server-url"]')?.content;
    const turnUsername   = document.querySelector('meta[name="turn-server-username"]')?.content;
    const turnCredential = document.querySelector('meta[name="turn-server-credential"]')?.content;

    if (turnUrl && turnUrl.trim() !== '') {
      servers.push({
        urls:       turnUrl.trim(),
        username:   turnUsername?.trim() || '',
        credential: turnCredential?.trim() || ''
      });
    }

    return { iceServers: servers };
  }

  // ─── Start a Call ──────────────────────────────────────────────────────────

  async startCall(callType) {
    this.callType = callType;
    this.isCaller = true;

    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: callType === "video"
      });

      this._showCallModal(callType, "Calling...", true);
      this._setupPeerConnection();

      // Add local tracks
      this.localStream.getTracks().forEach(track => {
        this.peerConnection.addTrack(track, this.localStream);
      });

      // Show local video
      if (callType === "video") {
        const localVideo = document.getElementById("localVideo");
        if (localVideo) {
          localVideo.srcObject = this.localStream;
        }
      }

      // Create offer
      const offer = await this.peerConnection.createOffer();
      await this.peerConnection.setLocalDescription(offer);

      // Send offer via Action Cable
      this.chatApp.conversationChannel?.sendCallSignal("offer", {
        sdp: offer.sdp,
        type: offer.type
      }, callType);

    } catch (err) {
      console.error("Error starting call:", err);
      this._showCallError("Could not access microphone/camera");
    }
  }

  // ─── Handle Incoming Signal ────────────────────────────────────────────────

  async handleSignal(data) {
    const { signal_type, signal_data, caller_id, call_type } = data;

    // Ignore signals from self
    if (caller_id === this.chatApp.currentUserId) return;

    switch (signal_type) {
      case "offer":
        await this._handleOffer(signal_data, call_type, caller_id);
        break;
      case "answer":
        await this._handleAnswer(signal_data);
        break;
      case "ice_candidate":
        await this._handleIceCandidate(signal_data);
        break;
      case "call_end":
        this._handleCallEnd();
        break;
      case "call_reject":
        this._handleCallRejected();
        break;
    }
  }

  async _handleOffer(offerData, callType, _callerId) {
    this.callType = callType;
    this.isCaller = false;
    this.pendingOffer = offerData;
    this._showIncomingCallModal(callType);
  }

  async acceptCall() {
    if (!this.pendingOffer) return;

    const incomingModal = document.getElementById("incomingCallModal");
    if (incomingModal) incomingModal.style.display = "none";

    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: this.callType === "video"
      });

      this._showCallModal(this.callType, "Connected", false);
      this._setupPeerConnection();

      // Add local tracks
      this.localStream.getTracks().forEach(track => {
        this.peerConnection.addTrack(track, this.localStream);
      });

      // Show local video
      if (this.callType === "video") {
        const localVideo = document.getElementById("localVideo");
        if (localVideo) localVideo.srcObject = this.localStream;
      }

      // Set remote description from offer
      await this.peerConnection.setRemoteDescription(
        new RTCSessionDescription(this.pendingOffer)
      );

      // Create answer
      const answer = await this.peerConnection.createAnswer();
      await this.peerConnection.setLocalDescription(answer);

      // Send answer
      this.chatApp.conversationChannel?.sendCallSignal("answer", {
        sdp: answer.sdp,
        type: answer.type
      }, this.callType);

      this.pendingOffer = null;

    } catch (err) {
      console.error("Error accepting call:", err);
      this._showCallError("Could not access microphone/camera");
    }
  }

  rejectCall() {
    const incomingModal = document.getElementById("incomingCallModal");
    if (incomingModal) incomingModal.style.display = "none";

    this.chatApp.conversationChannel?.sendCallSignal("call_reject", {}, this.callType);
    this.pendingOffer = null;
  }

  async _handleAnswer(answerData) {
    if (!this.peerConnection) return;
    await this.peerConnection.setRemoteDescription(
      new RTCSessionDescription(answerData)
    );
    const statusEl = document.getElementById("callStatus");
    if (statusEl) statusEl.textContent = "Connected";
  }

  async _handleIceCandidate(candidateData) {
    if (!this.peerConnection || !candidateData) return;
    try {
      await this.peerConnection.addIceCandidate(
        new RTCIceCandidate(candidateData)
      );
    } catch (err) {
      console.error("ICE candidate error:", err);
    }
  }

  _handleCallEnd() {
    this._cleanup();
    this._hideCallModal();
    this._showCallEndedToast();
  }

  _handleCallRejected() {
    this._cleanup();
    this._hideCallModal();
    this._showCallEndedToast("Call declined");
  }

  // ─── End Call ──────────────────────────────────────────────────────────────

  endCall() {
    this.chatApp.conversationChannel?.sendCallSignal("call_end", {}, this.callType);
    this._cleanup();
    this._hideCallModal();
  }

  // ─── Controls ──────────────────────────────────────────────────────────────

  toggleMute() {
    if (!this.localStream) return;
    this.isMuted = !this.isMuted;
    this.localStream.getAudioTracks().forEach(track => {
      track.enabled = !this.isMuted;
    });
    const btn = document.getElementById("muteBtn");
    if (btn) btn.classList.toggle("active", this.isMuted);
  }

  toggleVideo() {
    if (!this.localStream) return;
    this.isVideoOff = !this.isVideoOff;
    this.localStream.getVideoTracks().forEach(track => {
      track.enabled = !this.isVideoOff;
    });
    const btn = document.getElementById("videoToggleBtn");
    if (btn) btn.classList.toggle("active", this.isVideoOff);
  }

  // ─── Peer Connection Setup ─────────────────────────────────────────────────

  _setupPeerConnection() {
    this.peerConnection = new RTCPeerConnection(this.iceServers);

    // ICE candidates
    this.peerConnection.onicecandidate = (event) => {
      if (event.candidate) {
        this.chatApp.conversationChannel?.sendCallSignal("ice_candidate", {
          candidate: event.candidate.candidate,
          sdpMid: event.candidate.sdpMid,
          sdpMLineIndex: event.candidate.sdpMLineIndex
        }, this.callType);
      }
    };

    // Remote stream
    this.peerConnection.ontrack = (event) => {
      this.remoteStream = event.streams[0];
      const remoteVideo = document.getElementById("remoteVideo");
      if (remoteVideo) {
        remoteVideo.srcObject = this.remoteStream;
      }
    };

    // Connection state
    this.peerConnection.onconnectionstatechange = () => {
      const state = this.peerConnection.connectionState;
      const statusEl = document.getElementById("callStatus");
      if (statusEl) {
        if (state === "connected") statusEl.textContent = "Connected";
        else if (state === "disconnected" || state === "failed") {
          this._handleCallEnd();
        }
      }
    };
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────────

  _showCallModal(callType, status, isCalling) {
    const modal = document.getElementById("callModal");
    const title = document.getElementById("callModalTitle");
    const statusEl = document.getElementById("callStatus");
    const videoContainer = document.getElementById("callVideoContainer");
    const videoToggleBtn = document.getElementById("videoToggleBtn");

    if (modal) modal.style.display = "flex";
    if (title) title.textContent = callType === "video" ? "Video Call" : "Voice Call";
    if (statusEl) statusEl.textContent = isCalling ? "Calling..." : status;

    if (callType === "video") {
      if (videoContainer) videoContainer.style.display = "flex";
      if (videoToggleBtn) videoToggleBtn.style.display = "flex";
    }
  }

  _showIncomingCallModal(callType) {
    const modal = document.getElementById("incomingCallModal");
    const typeEl = document.getElementById("incomingCallType");

    if (modal) modal.style.display = "flex";
    if (typeEl) typeEl.textContent = callType === "video" ? "Incoming video call..." : "Incoming voice call...";

    // Play ringtone
    this._playRingtone();
  }

  _hideCallModal() {
    const callModal = document.getElementById("callModal");
    const incomingModal = document.getElementById("incomingCallModal");
    const videoContainer = document.getElementById("callVideoContainer");

    if (callModal) callModal.style.display = "none";
    if (incomingModal) incomingModal.style.display = "none";
    if (videoContainer) videoContainer.style.display = "none";

    this._stopRingtone();
  }

  _showCallError(message) {
    this._hideCallModal();
    const toast = document.createElement("div");
    toast.className = "chat-toast chat-toast-error";
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  }

  _showCallEndedToast(message = "Call ended") {
    const toast = document.createElement("div");
    toast.className = "chat-toast";
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(() => toast.remove(), 3000);
  }

  _playRingtone() {
    try {
      const ctx = new AudioContext();
      const oscillator = ctx.createOscillator();
      const gainNode = ctx.createGain();
      oscillator.connect(gainNode);
      gainNode.connect(ctx.destination);
      oscillator.frequency.setValueAtTime(440, ctx.currentTime);
      gainNode.gain.setValueAtTime(0.1, ctx.currentTime);
      oscillator.start();
      this._ringtoneCtx = ctx;
      this._ringtoneOsc = oscillator;
    } catch (e) {}
  }

  _stopRingtone() {
    try {
      this._ringtoneOsc?.stop();
      this._ringtoneCtx?.close();
    } catch (e) {}
  }

  _cleanup() {
    this.localStream?.getTracks().forEach(t => t.stop());
    this.peerConnection?.close();
    this.localStream = null;
    this.remoteStream = null;
    this.peerConnection = null;
    this.pendingOffer = null;
    this._stopRingtone();
  }
}
