# nexacon_messaging

[![Documentation](https://img.shields.io/badge/docs-readthedocs-blue.svg)](https://nexacon-messaging.readthedocs.io/)

Real-time messaging SDK for Nexacon — instant messaging with presence, typing indicators, delivery receipts, and message history.

## Features

- **Real-time messaging** — Send and receive messages instantly over WebSocket
- **Presence tracking** — Online/offline/away/busy status for users
- **Typing indicators** — Composing/paused chat state notifications (XEP-0085)
- **Delivery receipts** — Automatic delivery confirmation (XEP-0184)
- **Read receipts** — Manual read receipt sending
- **Message history** — Fetch paginated message history via REST API
- **Auto-reconnect** — Built-in reconnection with exponential backoff
- **Heartbeat/ping** — Keeps connection alive with periodic pings

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  nexacon_messaging: ^1.0.0
```

## Quick Start

```dart
import 'package:nexacon_messaging/nexacon_messaging.dart';

// Create the messaging instance
final messaging = NexaconMessaging(
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);

// Connect (domain is auto-appended internally)
final connected = await messaging.connect(
  nxid: '+255123456789@nxservice.quantumvision-tech.com',
  password: 'nx-token',
  wsUrl: 'wss://nxservice.quantumvision-tech.com/xmpp-websocket',
);

if (connected) {
  // Listen for incoming messages
  messaging.messageStream.listen((msg) {
    print('Message from ${msg.from}: ${msg.body}');
  });

  // Listen for presence changes
  messaging.presenceStream.listen((presence) {
    print('${presence.from} is ${presence.status}');
  });

  // Listen for typing indicators
  messaging.typingStream.listen((event) {
    print('${event.from} is ${event.isTyping ? "typing..." : "stopped typing"}');
  });

  // Listen for delivery receipts
  messaging.deliveryReceiptStream.listen((receipt) {
    print('Message ${receipt.messageId} delivered to ${receipt.from}');
  });

  // Send a message (just use phone number - domain auto-appended)
  await messaging.sendMessage(
    to: '+255987654321',
    message: 'Hello!',
  );

  // Send typing indicator (just use phone number)
  messaging.sendTypingIndicator('+255987654321');

  // Update your presence
  messaging.setOnline();    // Available
  messaging.setAway();      // Away
  messaging.setBusy();      // Do not disturb
  messaging.setOffline();   // Offline

  // Fetch message history (just use phone number)
  final history = await messaging.getMessageHistory(
    peer: '255987654321',  // without + prefix
    offset: 0,
    pageSize: 20,
  );
  print('Loaded ${history.messages.length} messages');
  print('Has next: ${history.hasNext}, next offset: ${history.nextOffset}');
}
```

## Connect with NX Token

If you have an NX token endpoint, you can connect in one step:

```dart
final connected = await messaging.connectWithToken(
  username: '+255123456789',
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);
```

## Presence Management

```dart
// Subscribe to a user's presence updates (just use phone number)
messaging.subscribeToPresence('+255987654321');

// Check cached presence
final status = messaging.getPresenceStatus('+255987654321');
print('Status: $status'); // NxPresenceStatus.online, .offline, .away, .busy

// Query presence via REST API
final presence = await messaging.getPresence('+255987654321');
```

## Typing Indicators

```dart
// User started typing (just use phone number)
messaging.sendTypingIndicator('+255987654321', isTyping: true);

// User stopped typing
messaging.sendTypingIndicator('+255987654321', isTyping: false);

// User is active in the chat
messaging.sendActiveState('+255987654321');

// User left the chat
messaging.sendInactiveState('+255987654321');
```

## Cleanup

```dart
await messaging.disconnect();
messaging.dispose();
```

## License

MIT
