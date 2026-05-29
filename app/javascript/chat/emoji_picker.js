const EMOJIS = [
  "😀","😃","😄","😁","😆","😅","🤣","😂","🙂","🙃","😉","😊","😇","🥰","😍",
  "🤩","😘","😗","😚","😙","😋","😛","😜","🤪","😝","🤑","🤗","🤭","🤫","🤔",
  "🤐","🤨","😐","😑","😶","😏","😒","🙄","😬","🤥","😌","😔","😪","🤤","😴",
  "😷","🤒","🤕","🤢","🤮","🤧","🥵","🥶","🥴","😵","🤯","🤠","🥳","😎","🤓",
  "🧐","😕","😟","🙁","☹️","😮","😯","😲","😳","🥺","😦","😧","😨","😰","😥",
  "😢","😭","😱","😖","😣","😞","😓","😩","😫","🥱","😤","😡","😠","🤬","😈",
  "👿","💀","☠️","💩","🤡","👹","👺","👻","👽","👾","🤖","😺","😸","😹","😻",
  "👋","🤚","🖐","✋","🖖","👌","🤌","🤏","✌️","🤞","🤟","🤘","🤙","👈","👉",
  "👆","🖕","👇","☝️","👍","👎","✊","👊","🤛","🤜","👏","🙌","👐","🤲","🤝",
  "🙏","✍️","💅","🤳","💪","🦾","🦿","🦵","🦶","👂","🦻","👃","🫀","🫁","🧠",
  "❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💔","❣️","💕","💞","💓","💗",
  "💖","💘","💝","💟","☮️","✝️","☪️","🕉","☸️","✡️","🔯","🕎","☯️","☦️","🛐",
  "🎉","🎊","🎈","🎁","🎀","🎗","🎟","🎫","🎖","🏆","🥇","🥈","🥉","🏅","🎪",
  "🔥","💥","✨","🌟","⭐","🌈","☀️","🌤","⛅","🌥","☁️","🌦","🌧","⛈","🌩",
  "🍕","🍔","🍟","🌭","🍿","🧂","🥓","🥚","🍳","🧇","🥞","🧈","🍞","🥐","🥖"
];

export class EmojiPicker {
  constructor() {
    this.picker = document.getElementById("emojiPicker");
    this.callback = null;
    this._built = false;
    this._setupOutsideClick();
  }

  toggle(triggerEl, callback) {
    this.callback = callback;

    if (!this._built) {
      this._build();
      this._built = true;
    }

    if (this.picker.style.display === "none" || !this.picker.style.display) {
      // Position near trigger
      const rect = triggerEl.getBoundingClientRect();
      this.picker.style.bottom = (window.innerHeight - rect.top + 8) + "px";
      this.picker.style.right = (window.innerWidth - rect.right) + "px";
      this.picker.style.display = "grid";
    } else {
      this.picker.style.display = "none";
    }
  }

  hide() {
    if (this.picker) this.picker.style.display = "none";
  }

  _build() {
    const grid = document.getElementById("emojiGrid");
    if (!grid) return;

    grid.innerHTML = EMOJIS.map(emoji =>
      `<button class="emoji-btn" onclick="event.stopPropagation()">${emoji}</button>`
    ).join("");

    grid.addEventListener("click", (e) => {
      const btn = e.target.closest(".emoji-btn");
      if (btn && this.callback) {
        this.callback(btn.textContent);
        this.hide();
      }
    });
  }

  _setupOutsideClick() {
    document.addEventListener("click", (e) => {
      if (this.picker &&
          !e.target.closest("#emojiPicker") &&
          !e.target.closest("#emojiBtn")) {
        this.hide();
      }
    });
  }
}
