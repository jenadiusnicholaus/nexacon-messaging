# Typing Indicators

## Overview

The SDK implements XEP-0085 (Chat State Notifications) for typing indicators. Five chat states are supported: `composing`, `paused`, `active`, `inactive`, and `gone`.

## Sending Typing Indicators

```dart
// User started typing
messaging.sendTypingIndicator('+255987654321', isTyping: true);

// User stopped typing
messaging.sendTypingIndicator('+255987654321', isTyping: false);
```

## Additional Chat States

```dart
// User is active in the chat (has it open)
messaging.sendActiveState('+255987654321');

// User left the chat (backgrounded the app)
messaging.sendInactiveState('+255987654321');

// User closed the chat
messaging.sendGoneState('+255987654321');
```

## Receiving Typing Events

```dart
messaging.typingStream.listen((event) {
  print('From: ${event.from}');
  print('Is typing: ${event.isTyping}');
  print('Timestamp: ${event.timestamp}');
});
```

### NxTypingEvent Fields

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | Sender JID |
| `isTyping` | `bool` | `true` for composing, `false` for paused |
| `timestamp` | `int` | Event timestamp in milliseconds |

## Typical Usage in a Chat UI

```dart
class ChatController {
  void onTextChanged(String text) {
    if (text.isNotEmpty) {
      messaging.sendTypingIndicator('+255987654321', isTyping: true);
    } else {
      messaging.sendTypingIndicator('+255987654321', isTyping: false);
    }
  }

  void onChatOpened() {
    messaging.sendActiveState('+255987654321');
  }

  void onChatClosed() {
    messaging.sendGoneState('+255987654321');
  }
}
```

!!! tip
    Send `composing` when the user starts typing and `paused` when they stop. The SDK handles the XMPP stanza formatting automatically.
