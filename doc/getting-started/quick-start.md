# Quick Start

This guide walks through a complete working example of using the Nexacon Messaging SDK.

## 1. Create the Messaging Instance

```dart
import 'package:nexacon_messaging/nexacon_messaging.dart';

final messaging = NexaconMessaging(
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);
```

## 2. Connect

You can connect with an NX ID and password directly:

```dart
final connected = await messaging.connect(
  nxid: '+255123456789@your-domain.com',
  password: 'nx-token',
  wsUrl: 'wss://your-domain.com/xmpp-websocket',
);

if (!connected) {
  print('Connection failed');
  return;
}
```

Or use the one-step token method:

```dart
final connected = await messaging.connectWithToken(
  username: '+255123456789',
  apiKey: 'your-api-key',
  secretKey: 'your-secret-key',
);
```

## 3. Listen for Events

```dart
// Incoming messages
messaging.messageStream.listen((msg) {
  print('Message from ${msg.from}: ${msg.body}');
});

// Presence changes
messaging.presenceStream.listen((presence) {
  print('${presence.from} is ${presence.status}');
});

// Typing indicators
messaging.typingStream.listen((event) {
  print('${event.from} is ${event.isTyping ? "typing..." : "stopped typing"}');
});

// Delivery receipts
messaging.deliveryReceiptStream.listen((receipt) {
  print('Message ${receipt.messageId} delivered to ${receipt.from}');
});

// Connection state changes
messaging.connectionStateStream.listen((state) {
  print('Connection: $state');
});
```

## 4. Send a Message

```dart
await messaging.sendMessage(
  to: '+255987654321',  // Phone number — domain auto-appended
  message: 'Hello!',
);
```

!!! note "Auto domain"
You can use bare phone numbers like `+255987654321`. The SDK automatically appends your connection domain (e.g., `@your-domain.com`) based on your JID.

## 5. Update Presence

```dart
messaging.setOnline();    // Available
messaging.setAway();      // Away
messaging.setBusy();      // Do not disturb
messaging.setOffline();   // Offline
```

## 6. Fetch Message History

```dart
final history = await messaging.getMessageHistory(
  peer: '255987654321',  // Phone number without +
  offset: 0,
  pageSize: 50,
);

print('Total: ${history.total}');
print('Messages: ${history.messages.length}');
print('Has next: ${history.hasNext}');
print('Next offset: ${history.nextOffset}');

for (final msg in history.messages) {
  print('${msg.isMe ? "Me" : msg.from}: ${msg.body}');
  print('  Timestamp: ${DateTime.fromMillisecondsSinceEpoch(msg.timestamp)}');
}
```

## 7. Cleanup

```dart
await messaging.disconnect();
messaging.dispose();
```

## Complete Example

```dart
import 'package:nexacon_messaging/nexacon_messaging.dart';

class ChatService {
  late final NexaconMessaging messaging;

  Future<void> init() async {
    messaging = NexaconMessaging(
      apiKey: 'your-api-key',
      secretKey: 'your-secret-key',
    );

    // Listen to events
    messaging.messageStream.listen(_onMessage);
    messaging.presenceStream.listen(_onPresence);
    messaging.typingStream.listen(_onTyping);

    // Connect
    final connected = await messaging.connectWithToken(
      username: '+255123456789',
      apiKey: 'your-api-key',
      secretKey: 'your-secret-key',
    );

    if (connected) {
      messaging.setOnline();
    }
  }

  void _onMessage(NxMessage msg) {
    print('${msg.from}: ${msg.body}');
  }

  void _onPresence(NxPresence presence) {
    print('${presence.from} is ${presence.status}');
  }

  void _onTyping(NxTypingEvent event) {
    print('${event.from} is ${event.isTyping ? "typing..." : "stopped"}');
  }

  Future<void> sendMessage(String to, String text) async {
    await messaging.sendMessage(to: to, message: text);
  }

  Future<void> loadHistory(String peer) async {
    final history = await messaging.getMessageHistory(
      peer: peer,
      offset: 0,
      pageSize: 50,
    );

    for (final msg in history.messages) {
      print('${msg.isMe ? "Me" : msg.from}: ${msg.body}');
    }
  }

  void dispose() {
    messaging.setOffline();
    messaging.disconnect();
    messaging.dispose();
  }
}
```
