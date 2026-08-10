# nexacon_messaging

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

// Connect
final connected = await messaging.connect(
  nxid: 'user@nxservice.quantumvision-tech.com',
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

  // Send a message
  await messaging.sendMessage(
    to: 'peer@nxservice.quantumvision-tech.com',
    message: 'Hello!',
  );

  // Send typing indicator
  messaging.sendTypingIndicator('peer@nxservice.quantumvision-tech.com');

  // Update your presence
  messaging.setOnline();    // Available
  messaging.setAway();      // Away
  messaging.setBusy();      // Do not disturb
  messaging.setOffline();   // Offline

  // Fetch message history
  final history = await messaging.getMessageHistory(
    peer: 'peer@nxservice.quantumvision-tech.com',
    page: 1,
    pageSize: 20,
  );
  print('Loaded ${history.messages.length} messages');
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
// Subscribe to a user's presence updates
messaging.subscribeToPresence('peer@nxservice.quantumvision-tech.com');

// Check cached presence
final status = messaging.getPresenceStatus('peer@nxservice.quantumvision-tech.com');
print('Status: $status'); // NxPresenceStatus.online, .offline, .away, .busy

// Query presence via REST API
final presence = await messaging.getPresence('peer@nxservice.quantumvision-tech.com');
```

## Typing Indicators

```dart
// User started typing
messaging.sendTypingIndicator('peer@nxservice.quantumvision-tech.com', isTyping: true);

// User stopped typing
messaging.sendTypingIndicator('peer@nxservice.quantumvision-tech.com', isTyping: false);

// User is active in the chat
messaging.sendActiveState('peer@nxservice.quantumvision-tech.com');

// User left the chat
messaging.sendInactiveState('peer@nxservice.quantumvision-tech.com');
```

## Cleanup

```dart
await messaging.disconnect();
messaging.dispose();
```

## License

MIT
