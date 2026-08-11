# Nexacon Messaging SDK

Real-time messaging SDK for Nexacon — instant messaging with presence, typing indicators, delivery receipts, and message history.

## Features

- **Real-time messaging** — Send and receive messages instantly over WebSocket
- **Presence tracking** — Online/offline/away/busy status for users
- **Typing indicators** — Composing/paused chat state notifications (XEP-0085)
- **Delivery receipts** — Automatic delivery confirmation (XEP-0184)
- **Read receipts** — Manual read receipt sending
- **Message history** — Fetch paginated message history via REST API with offset-based pagination
- **Auto-reconnect** — Built-in reconnection with exponential backoff
- **Heartbeat/ping** — Keeps connection alive with periodic pings

## Platform Support

| Android | iOS | Linux | macOS | Web | Windows |
| :-----: | :-: | :---: | :---: | :-: | :-----: |
|   ✅    | ✅  |  ✅   |  ✅   | ✅  |   ✅    |

## Quick Example

```dart
import 'package:nexacon_messaging/nexacon_messaging.dart';

final messaging = NexaconMessaging(
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);

final connected = await messaging.connect(
  nxid: '+255123456789@your-domain.com',
  password: 'nx-token',
  wsUrl: 'wss://your-domain.com/xmpp-websocket',
);

if (connected) {
  messaging.messageStream.listen((msg) {
    print('Message from ${msg.from}: ${msg.body}');
  });

  await messaging.sendMessage(
    to: '+255987654321',
    message: 'Hello!',
  );
}
```

## Next Steps

- [Installation](getting-started/installation.md) — Add the SDK to your project
- [Quick Start](getting-started/quick-start.md) — Full working example
- [API Reference](api/nexacon-messaging.md) — Complete class documentation
