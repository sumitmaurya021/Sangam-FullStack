export class VoiceRecorder {
  constructor(container, onSendCallback) {
    this.container = container;
    this.micBtn = container.querySelector('.voice-record-btn');
    this.uiContainer = container.querySelector('.voice-recording-ui');
    this.timerEl = container.querySelector('.recording-timer');
    this.cancelBtn = container.querySelector('.record-cancel-btn');
    this.sendBtn = container.querySelector('.record-send-btn');
    this.defaultInputArea = container.querySelector('.default-input-area');
    
    this.onSendCallback = onSendCallback;

    this.mediaRecorder = null;
    this.audioChunks = [];
    this.startTime = null;
    this.timerInterval = null;

    if (this.micBtn) {
      this.bindEvents();
    }
  }

  bindEvents() {
    this.micBtn.addEventListener('click', (e) => {
      e.preventDefault();
      this.startRecording();
    });
    this.cancelBtn.addEventListener('click', (e) => {
      e.preventDefault();
      this.cancelRecording();
    });
    this.sendBtn.addEventListener('click', (e) => {
      e.preventDefault();
      this.stopAndSendRecording();
    });
  }

  async startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      this.mediaRecorder = new MediaRecorder(stream);
      this.audioChunks = [];
      this.mediaRecorder.ondataavailable = (e) => {
        if (e.data.size > 0) this.audioChunks.push(e.data);
      };
      
      this.mediaRecorder.start();
      this.startTime = Date.now();
      
      // Update UI
      if (this.uiContainer) this.uiContainer.style.display = 'flex';
      if (this.defaultInputArea) this.defaultInputArea.style.display = 'none';
      
      this.timerInterval = setInterval(() => this.updateTimer(), 1000);
    } catch (err) {
      console.error("Microphone access denied or error", err);
      alert("Could not access microphone. Please check your browser permissions.");
    }
  }

  updateTimer() {
    const elapsed = Math.floor((Date.now() - this.startTime) / 1000);
    const mins = Math.floor(elapsed / 60);
    const secs = (elapsed % 60).toString().padStart(2, '0');
    if (this.timerEl) this.timerEl.textContent = `${mins}:${secs}`;
  }

  cancelRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.onstop = null; // Prevent sending
      this.mediaRecorder.stop();
    }
    this.resetUI();
  }

  stopAndSendRecording() {
    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.onstop = () => {
        // webm is standard for MediaRecorder on modern browsers
        const audioBlob = new Blob(this.audioChunks, { type: 'audio/webm' });
        this.resetUI();
        if (this.onSendCallback) this.onSendCallback(audioBlob);
      };
      this.mediaRecorder.stop();
    }
  }

  resetUI() {
    clearInterval(this.timerInterval);
    if (this.timerEl) this.timerEl.textContent = '0:00';
    if (this.uiContainer) this.uiContainer.style.display = 'none';
    if (this.defaultInputArea) this.defaultInputArea.style.display = 'flex';
    
    if (this.mediaRecorder && this.mediaRecorder.stream) {
      this.mediaRecorder.stream.getTracks().forEach(track => track.stop());
    }
  }
}

window.VoiceRecorder = VoiceRecorder;

document.addEventListener('turbo:load', () => {
  window.VoiceRecorder = VoiceRecorder;
});
