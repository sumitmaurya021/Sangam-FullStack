/**
 * ULTRA-PREMIUM AUTHENTICATION MODULE JS
 * Bulletproof Tab Auto-Slider Engine, Password Strength Meter, OTP Input & Submit Spinners
 */

(function () {
  'use strict';

  let sliderTimer = null;
  let currentTabIndex = 0;

  // Globally accessible tab switcher function (bulletproof fail-safe)
  window.apSwitchTab = function (index) {
    const tabs = document.querySelectorAll('#apShowcaseTabs .ap-tab-item');
    const cards = document.querySelectorAll('.ap-preview-card');

    if (!tabs.length || !cards.length) return;

    currentTabIndex = index % tabs.length;

    tabs.forEach((tab, i) => {
      const progressBar = tab.querySelector('.ap-tab-progress-bar');
      if (i === currentTabIndex) {
        tab.classList.add('is-active');
        if (progressBar) {
          progressBar.style.animation = 'none';
          progressBar.offsetHeight; // Force DOM reflow to restart CSS animation
          progressBar.style.animation = 'ap-tab-timer 3.5s linear forwards';
        }
      } else {
        tab.classList.remove('is-active');
        if (progressBar) {
          progressBar.style.animation = 'none';
        }
      }
    });

    cards.forEach((card, i) => {
      if (i === currentTabIndex) {
        card.classList.add('is-active');
      } else {
        card.classList.remove('is-active');
      }
    });

    // Reset & restart auto interval timer
    if (sliderTimer) clearInterval(sliderTimer);
    sliderTimer = setInterval(function () {
      const nextIndex = (currentTabIndex + 1) % tabs.length;
      window.apSwitchTab(nextIndex);
    }, 3500);
  };

  function initAuthPremium() {
    // Add active class to body for strict 100vh layout
    if (document.querySelector('.ap-viewport')) {
      document.documentElement.classList.add('auth-active');
      document.body.classList.add('auth-active');
    } else {
      document.documentElement.classList.remove('auth-active');
      document.body.classList.remove('auth-active');
      return;
    }

    initCanvasAnimation();
    initShowcaseSlider();
    initPasswordStrengthMeter();
    initOtpInputs();
    initFormSubmitSpinners();
  }

  // 1. DYNAMIC AMBIENT PARTICLE CANVAS
  function initCanvasAnimation() {
    const canvas = document.getElementById('apCanvas');
    if (!canvas) return;

    const ctx = canvas.getContext('2d');
    let width = (canvas.width = window.innerWidth);
    let height = (canvas.height = window.innerHeight);

    let particles = [];
    const particleCount = Math.min(Math.floor((width * height) / 16000), 55);

    class Particle {
      constructor() {
        this.reset();
      }

      reset() {
        this.x = Math.random() * width;
        this.y = Math.random() * height;
        this.vx = (Math.random() - 0.5) * 0.4;
        this.vy = (Math.random() - 0.5) * 0.4;
        this.radius = Math.random() * 1.6 + 0.8;
        this.alpha = Math.random() * 0.55 + 0.2;
      }

      update() {
        this.x += this.vx;
        this.y += this.vy;

        if (this.x < 0 || this.x > width) this.vx *= -1;
        if (this.y < 0 || this.y > height) this.vy *= -1;
      }

      draw() {
        ctx.beginPath();
        ctx.arc(this.x, this.y, this.radius, 0, Math.PI * 2);
        ctx.fillStyle = `rgba(165, 180, 252, ${this.alpha})`;
        ctx.fill();
      }
    }

    for (let i = 0; i < particleCount; i++) {
      particles.push(new Particle());
    }

    function render() {
      ctx.clearRect(0, 0, width, height);

      for (let i = 0; i < particles.length; i++) {
        for (let j = i + 1; j < particles.length; j++) {
          const dx = particles[i].x - particles[j].x;
          const dy = particles[i].y - particles[j].y;
          const dist = Math.sqrt(dx * dx + dy * dy);

          if (dist < 120) {
            ctx.beginPath();
            ctx.moveTo(particles[i].x, particles[i].y);
            ctx.lineTo(particles[j].x, particles[j].y);
            ctx.strokeStyle = `rgba(99, 102, 241, ${0.12 * (1 - dist / 120)})`;
            ctx.lineWidth = 0.8;
            ctx.stroke();
          }
        }
      }

      particles.forEach((p) => {
        p.update();
        p.draw();
      });

      requestAnimationFrame(render);
    }

    render();

    window.addEventListener('resize', function () {
      width = canvas.width = window.innerWidth;
      height = canvas.height = window.innerHeight;
    });
  }

  // 2. SHOWCASE SLIDER INITIALIZER
  function initShowcaseSlider() {
    const tabs = document.querySelectorAll('#apShowcaseTabs .ap-tab-item');
    if (!tabs.length) return;

    tabs.forEach((tab) => {
      tab.addEventListener('click', function () {
        const idx = parseInt(this.getAttribute('data-tab'), 10);
        window.apSwitchTab(idx);
      });
    });

    // Start auto slider on tab 0
    window.apSwitchTab(0);
  }

  // 3. GLOBAL DELEGATED PASSWORD TOGGLE
  document.addEventListener('click', function (e) {
    const toggleBtn = e.target.closest('[data-toggle-password]');
    if (!toggleBtn) return;

    e.preventDefault();
    e.stopPropagation();

    const targetId = toggleBtn.getAttribute('data-toggle-password');
    const wrapper = toggleBtn.closest('.ap-input-wrapper');
    const input = (targetId ? document.getElementById(targetId) : null) || (wrapper ? wrapper.querySelector('input') : null);

    if (!input) return;

    const isPassword = input.type === 'password';
    input.type = isPassword ? 'text' : 'password';

    toggleBtn.innerHTML = isPassword ? `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"></path>
        <line x1="1" y1="1" x2="23" y2="23"></line>
      </svg>
    ` : `
      <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
        <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"></path>
        <circle cx="12" cy="12" r="3"></circle>
      </svg>
    `;
  });

  // 4. LIVE PASSWORD STRENGTH METER
  function initPasswordStrengthMeter() {
    const passwordInputs = document.querySelectorAll('[data-password-strength]');

    passwordInputs.forEach((input) => {
      const container = input.closest('.ap-form-group').querySelector('.ap-strength-meter');
      if (!container) return;

      const label = container.querySelector('.ap-strength-label');

      input.addEventListener('input', function () {
        const val = this.value;
        let score = 0;

        if (val.length >= 6) score++;
        if (val.length >= 10 && /[A-Z]/.test(val)) score++;
        if (/[0-9]/.test(val) && /[^A-Za-z0-9]/.test(val)) score++;
        if (val.length >= 12 && score >= 2) score++;

        if (val.length === 0) score = 0;

        container.setAttribute('data-score', score);

        const labels = ['Too weak', 'Fair password', 'Strong password', 'Ultra secure'];
        if (label) {
          label.textContent = val.length === 0 ? '' : labels[Math.max(0, score - 1)] || '';
        }
      });
    });
  }

  // 5. MULTI-BOX OTP INPUT
  function initOtpInputs() {
    const otpContainer = document.querySelector('[data-otp-container]');
    if (!otpContainer) return;

    const boxes = Array.from(otpContainer.querySelectorAll('.ap-otp-box'));
    const hiddenInput = document.querySelector(otpContainer.getAttribute('data-otp-target') || 'input[name="otp_code"]');

    function syncOtpValue() {
      const val = boxes.map((b) => b.value).join('');
      if (hiddenInput) hiddenInput.value = val;
    }

    boxes.forEach((box, idx) => {
      box.addEventListener('input', function (e) {
        const val = this.value;

        if (val.length > 0) {
          this.value = val[val.length - 1];
          this.classList.add('is-filled');
          if (idx < boxes.length - 1) {
            boxes[idx + 1].focus();
          }
        } else {
          this.classList.remove('is-filled');
        }

        syncOtpValue();
      });

      box.addEventListener('keydown', function (e) {
        if (e.key === 'Backspace' && !this.value && idx > 0) {
          boxes[idx - 1].focus();
          boxes[idx - 1].value = '';
          boxes[idx - 1].classList.remove('is-filled');
          syncOtpValue();
        }
      });

      box.addEventListener('paste', function (e) {
        e.preventDefault();
        const pastedData = (e.clipboardData || window.clipboardData).getData('text').trim();
        if (!pastedData) return;

        const digits = pastedData.replace(/\D/g, '').split('');
        digits.forEach((digit, i) => {
          if (boxes[i]) {
            boxes[i].value = digit;
            boxes[i].classList.add('is-filled');
          }
        });

        const nextFocusIndex = Math.min(digits.length, boxes.length - 1);
        boxes[nextFocusIndex].focus();
        syncOtpValue();
      });
    });
  }

  // 6. FORM SUBMIT LOADING SPINNER
  function initFormSubmitSpinners() {
    document.querySelectorAll('.ap-form').forEach((form) => {
      form.addEventListener('submit', function () {
        const submitBtn = this.querySelector('.ap-btn-primary');
        if (submitBtn) {
          submitBtn.classList.add('is-loading');
        }
      });
    });
  }

  document.addEventListener('turbo:load', initAuthPremium);
  document.addEventListener('DOMContentLoaded', initAuthPremium);

  // Initial trigger if already loaded
  if (document.readyState === 'complete' || document.readyState === 'interactive') {
    initAuthPremium();
  }
})();
