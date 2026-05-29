import { ChatWidget } from "chat/chat_widget";

let _widget = null;

function bootWidget() {
  const data = window.WIDGET_DATA;
  if (!data || _widget) return;
  _widget = new ChatWidget(data);
  window.chatWidget = _widget;
}

document.addEventListener("turbo:before-visit", () => {
  // Keep widget alive across navigation — just reset flag if on conversations page
  if (window.location.pathname.startsWith("/conversations")) {
    _widget = null;
    window.chatWidget = null;
  }
});

document.addEventListener("turbo:load", bootWidget);
document.addEventListener("DOMContentLoaded", bootWidget);
