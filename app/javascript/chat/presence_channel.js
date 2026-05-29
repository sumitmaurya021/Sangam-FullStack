import consumer from "channels/consumer";

export class PresenceChannel {
  constructor(chatApp) {
    this.chatApp = chatApp;
    this._subscribe();
  }

  _subscribe() {
    consumer.subscriptions.create(
      { channel: "PresenceChannel" },
      {
        connected: () => console.log("[PresenceChannel] connected"),
        received: (data) => {
          if (data.type === "presence_update") {
            this.chatApp.handlePresenceUpdate(data);
          }
        }
      }
    );
  }
}
