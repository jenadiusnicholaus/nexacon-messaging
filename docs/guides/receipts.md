# Delivery & Read Receipts

## Overview

The SDK implements XEP-0184 (Message Delivery Receipts) for confirming message delivery.

## Delivery Receipts

### Automatic receiving

When you receive a message, the SDK automatically sends a delivery receipt back to the sender. No code needed.

### Tracking sent message delivery

The `sendMessage` method returns a `Future` that completes when a delivery receipt is received:

```dart
try {
  await messaging.sendMessage(
    to: '+255987654321',
    message: 'Hello!',
    deliveryTimeout: const Duration(seconds: 15),
  );
  print('Message delivered!');
} catch (e) {
  print('Delivery timed out');
}
```

### Listening to delivery receipts

```dart
messaging.deliveryReceiptStream.listen((receipt) {
  print('Message ${receipt.messageId} delivered to ${receipt.from}');
  print('Timestamp: ${receipt.timestamp}');
});
```

### NxDeliveryReceipt Fields

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | Recipient JID who confirmed delivery |
| `messageId` | `String?` | ID of the delivered message |
| `timestamp` | `int` | Receipt timestamp in milliseconds |

## Read Receipts

Read receipts are sent manually when the user opens/reads a message:

```dart
messaging.sendReadReceipt('+255987654321', 'msg_1234567890');
```

### Listening to read receipts

```dart
messaging.readReceiptStream.listen((receipt) {
  print('Message ${receipt.messageId} read by ${receipt.from}');
});
```

### NxReadReceipt Fields

| Field | Type | Description |
|-------|------|-------------|
| `from` | `String?` | Recipient JID who read the message |
| `messageId` | `String?` | ID of the read message |
| `timestamp` | `int` | Receipt timestamp in milliseconds |
