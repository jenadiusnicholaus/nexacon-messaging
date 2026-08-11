# Messaging

## Sending Messages

### Send a message (with delivery tracking)

```dart
await messaging.sendMessage(
  to: '+255987654321',
  message: 'Hello!',
);
```

The `sendMessage` method:

1. Generates a unique message ID
2. Sends the message over WebSocket
3. Returns a `Future` that completes when a delivery receipt is received
4. Times out after 30 seconds if no receipt arrives

### Parameters

| Parameter         | Type       | Required | Default        | Description                           |
| ----------------- | ---------- | -------- | -------------- | ------------------------------------- |
| `to`              | `String`   | Yes      | —              | Recipient phone number or full JID    |
| `message`         | `String`   | Yes      | —              | Message body (plain text)             |
| `messageId`       | `String?`  | No       | Auto-generated | Custom message ID                     |
| `deliveryTimeout` | `Duration` | No       | 30s            | How long to wait for delivery receipt |

### Send raw message (no delivery tracking)

```dart
await messaging.sendRawMessage(
  to: '+255987654321',
  message: 'Hello!',
);
```

## Receiving Messages

```dart
messaging.messageStream.listen((msg) {
  print('From: ${msg.from}');
  print('To: ${msg.to}');
  print('Body: ${msg.body}');
  print('ID: ${msg.id}');
  print('Type: ${msg.type}');
  print('Timestamp: ${msg.timestamp}');
});
```

### NxMessage Fields

| Field       | Type      | Description                   |
| ----------- | --------- | ----------------------------- |
| `id`        | `String?` | Message ID                    |
| `from`      | `String?` | Sender JID                    |
| `to`        | `String?` | Recipient JID                 |
| `body`      | `String?` | Message body (plain text)     |
| `type`      | `String?` | Message type (usually `chat`) |
| `timestamp` | `int`     | Timestamp in milliseconds     |
| `originId`  | `String?` | Origin ID for deduplication   |

## Auto Domain Normalization

The SDK automatically appends the XMPP domain to bare phone numbers:

```dart
// These are equivalent:
await messaging.sendMessage(to: '+255987654321', message: 'Hi');
await messaging.sendMessage(to: '+255987654321@your-domain.com', message: 'Hi');
```

The domain is extracted from your JID after connection. If not connected, it falls back to a default domain.

## Message Body Format

Messages are sent as **plain text** — no JSON wrapping. This ensures compatibility with standard XMPP clients.

```dart
// Sent as plain text over the wire
await messaging.sendMessage(to: '+255987654321', message: 'Hello world');
```
