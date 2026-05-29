import consumer from "channels/consumer";

export class ConversationChannel {
  constructor(conversationId, chatApp) {
    this.conversationId = conversationId;
    this.chatApp        = chatApp;
    this.subscription   = null;
    this._subscribe();
  }

  _subscribe() {
    this.subscription = consumer.subscriptions.create(
      { channel: "ConversationChannel", conversation_id: this.conversationId },
      {
        connected: () => {
          console.log(`[Cable] ConversationChannel connected (conv ${this.conversationId})`);
          // Mark messages as read as soon as we connect
          this.markRead();
        },
        disconnected: () => {
          console.log("[Cable] ConversationChannel disconnected");
        },
        rejected: () => {
          console.error("[Cable] ConversationChannel rejected — check authorization");
        },
        received: (data) => {
          console.log("[Cable] received:", data.type, data);
          this._dispatch(data);
        }
      }
    );
  }

  sendTyping(isTyping) {
    this.subscription?.perform("typing", {
      conversation_id: this.conversationId,
      is_typing: isTyping
    });
  }

  markRead() {
    this.subscription?.perform("mark_read", {
      conversation_id: this.conversationId
    });
  }

  sendCallSignal(signalType, signalData, callType) {
    this.subscription?.perform("call_signal", {
      conversation_id: this.conversationId,
      signal_type: signalType,
      signal_data: signalData,
      call_type: callType
    });
  }

  _dispatch(data) {
    switch (data.type) {
      case "new_message":
        this.chatApp.handleNewMessage(data);
        break;
      case "message_deleted":
        this.chatApp.handleMessageDeleted(data);
        break;
      case "messages_read":
        this.chatApp.handleMessagesRead(data);
        break;
      case "typing":
        this.chatApp.handleTyping(data);
        break;
      case "call_signal":
        this.chatApp.webrtc?.handleSignal(data);
        break;
      default:
        console.warn("[Cable] Unknown message type:", data.type);
    }
  }

  unsubscribe() {
    this.subscription?.unsubscribe();
  }
}
