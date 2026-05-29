import consumer from "channels/consumer";

export class UserChatChannel {
  constructor(userId, chatApp) {
    this.userId  = userId;
    this.chatApp = chatApp;
    this._subscribe();
  }

  _subscribe() {
    consumer.subscriptions.create(
      { channel: "UserChatChannel" },
      {
        connected: () => console.log("[UserChatChannel] connected"),
        received: (data) => {
          console.log("[UserChatChannel] received:", data.type);
          if (data.type === "new_message_notification") {
            this.chatApp.handleNewMessageNotification(data);
          }
        }
      }
    );
  }
}
