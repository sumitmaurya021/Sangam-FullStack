import { ChatWidget } from "chat/chat_widget";

let _widgetBooted = false;

function bootWidget() {
  const data = window.WIDGET_DATA;
  if (!data) return;
  if (_widgetBooted && window.chatWidget) return;
  _widgetBooted = true;
  window.chatWidget = new ChatWidget(data);
}

document.addEventListener("turbo:before-visit", () => {
  _widgetBooted = false;
  // Don't null chatWidget — keep mini windows open across navigation
});

document.addEventListener("turbo:load", bootWidget);

if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", bootWidget);
} else {
  setTimeout(bootWidget, 0);
}
